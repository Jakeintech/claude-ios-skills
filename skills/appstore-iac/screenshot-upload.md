# Screenshot Upload Flow

The ASC API requires a 4-step process per screenshot. This is the most complex part of appstore-iac.

## Device Directory Mapping

| Directory Name | ASC screenshotDisplayType | Device |
|---|---|---|
| `iphone-6.9` | `APP_IPHONE_67` | iPhone 16 Pro Max, 15 Pro Max |
| `iphone-6.7` | `APP_IPHONE_67` | iPhone 14 Pro Max (same type) |
| `iphone-6.5` | `APP_IPHONE_65` | iPhone 11 Pro Max, XS Max |
| `iphone-6.1` | `APP_IPHONE_61` | iPhone 14 Pro, 15 Pro |
| `iphone-5.8` | `APP_IPHONE_58` | iPhone X, XS, 11 Pro |
| `iphone-5.5` | `APP_IPHONE_55` | iPhone 8 Plus, 7 Plus |
| `ipad-13` | `APP_IPAD_PRO_3GEN_129` | 12.9" iPad Pro (3rd gen+) |
| `ipad-11` | `APP_IPAD_PRO_3GEN_11` | 11" iPad Pro |
| `watch-ultra` | `APP_WATCH_ULTRA` | Apple Watch Ultra |
| `watch-series10` | `APP_WATCH_SERIES_10` | Apple Watch Series 10 |

`APP_IPHONE_67` is the current required minimum for iPhone apps.

## Step 1: Create Screenshot Set

One set per display type per localization.

```
POST /v1/appScreenshotSets
```

```json
{
  "data": {
    "type": "appScreenshotSets",
    "attributes": {
      "screenshotDisplayType": "APP_IPHONE_67"
    },
    "relationships": {
      "appStoreVersionLocalization": {
        "data": { "type": "appStoreVersionLocalizations", "id": "{loc_id}" }
      }
    }
  }
}
```

## Step 2: Reserve Upload

```
POST /v1/appScreenshots
```

```json
{
  "data": {
    "type": "appScreenshots",
    "attributes": {
      "fileName": "01-home.png",
      "fileSize": 1234567
    },
    "relationships": {
      "appScreenshotSet": {
        "data": { "type": "appScreenshotSets", "id": "{set_id}" }
      }
    }
  }
}
```

Response includes:
- `data.id` — screenshot ID (needed for commit)
- `data.attributes.uploadOperations` — array of upload chunks
- `data.attributes.assetDeliveryState` — should be `AWAITING_UPLOAD`

Each upload operation:
```json
{
  "method": "PUT",
  "url": "https://signed-s3-url...",
  "length": 1234567,
  "offset": 0,
  "requestHeaders": [
    { "name": "Content-Type", "value": "image/png" }
  ]
}
```

## Step 3: Upload Binary

For most screenshots (< 50MB), there's one upload operation covering the entire file:

```bash
curl -s -X PUT \
  -H "Content-Type: image/png" \
  --data-binary @screenshot.png \
  "$UPLOAD_URL"
```

For chunked uploads (multiple operations):
```bash
dd if=screenshot.png bs=1 skip=$OFFSET count=$LENGTH 2>/dev/null | \
  curl -s -X PUT -H "Content-Type: image/png" --data-binary @- "$UPLOAD_URL"
```

**You MUST execute ALL upload operations.** The upload is not complete until every chunk is uploaded.

## Step 4: Commit Upload

```
PATCH /v1/appScreenshots/{screenshot_id}
```

```json
{
  "data": {
    "type": "appScreenshots",
    "id": "{screenshot_id}",
    "attributes": {
      "uploaded": true,
      "sourceFileChecksum": "{md5_hex}"
    }
  }
}
```

Generate checksum: `md5 -q screenshot.png`

**If you skip this step, the screenshot stays in `AWAITING_UPLOAD` state forever.**

## Idempotency

Before uploading, check if an identical screenshot already exists:

1. List existing screenshots: `GET /v1/appScreenshotSets/{setId}/appScreenshots`
2. Compare `attributes.sourceFileChecksum` against `md5 -q local_file.png`
3. Checksum matches → skip upload
4. Checksum differs → delete old, upload new

## Ordering

Reorder screenshots via:

```
PATCH /v1/appScreenshotSets/{setId}/relationships/appScreenshots
```

```json
{
  "data": [
    { "type": "appScreenshots", "id": "{first_id}" },
    { "type": "appScreenshots", "id": "{second_id}" },
    { "type": "appScreenshots", "id": "{third_id}" }
  ]
}
```

Order matches sorted filename order from the local directory.

**⚠ The reorder endpoint returns `204 No Content`** with an empty response body. A JSON-parsing API helper must check `response.text.strip()` before `json.loads`, otherwise it raises `JSONDecodeError`. Standard pattern:

```python
text = resp.read().decode()
return resp.status, (json.loads(text) if text.strip() else {})
```

## Constraints

- Formats: `.jpeg`, `.jpg`, `.png`
- 1-10 screenshots per set
- Dimensions must match the `screenshotDisplayType` exactly
- Type strings are plural: `appScreenshotSets`, `appScreenshots`

## Full Pipeline (pseudo-code)

```
for each device_dir in screenshots/appstore/:
  display_type = map_directory(device_dir)
  set_id = find_or_create_set(loc_id, display_type)
  existing = list_screenshots(set_id)
  existing_map = {s.fileName: (s.id, s.checksum) for s in existing}
  
  new_order = []
  for file in sorted(device_dir/*.png):
    checksum = md5(file)
    if file.name in existing_map and existing_map[file.name].checksum == checksum:
      new_order.append(existing_map[file.name].id)  # keep existing
    else:
      if file.name in existing_map:
        delete(existing_map[file.name].id)  # changed — remove old
      screenshot_id = reserve(set_id, file.name, file.size)
      upload(file, upload_ops)
      commit(screenshot_id, checksum)
      new_order.append(screenshot_id)
  
  reorder(set_id, new_order)
```
