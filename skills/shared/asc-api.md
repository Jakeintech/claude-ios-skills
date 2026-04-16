# App Store Connect API — Shared Reference

Common patterns for all skills that interact with the App Store Connect API.

## Authentication

Generate a JWT signed with ES256 using PyJWT. Never use openssl (produces DER signatures, JWT ES256 needs raw R||S).

```bash
JWT=$(python3 -c "
import jwt, time
key = open('$ASC_PRIVATE_KEY_PATH', 'r').read()
print(jwt.encode(
    {'iss': '$ASC_ISSUER_ID', 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
    key, algorithm='ES256', headers={'kid': '$ASC_KEY_ID'}
))
")
```

Requires `pip3 install PyJWT cryptography` (one-time setup).

## Credential Verification

Run before any API call:

```bash
echo "Issuer: ${ASC_ISSUER_ID:?Missing ASC_ISSUER_ID}"
echo "Key ID: ${ASC_KEY_ID:?Missing ASC_KEY_ID}"
test -f "$ASC_PRIVATE_KEY_PATH" && echo "Key file: OK" || echo "ERROR: .p8 not found at $ASC_PRIVATE_KEY_PATH"
```

If missing, tell user to set env vars in `~/.claude/settings.json` under `env`:
- `ASC_ISSUER_ID` — from App Store Connect > Users and Access > Integrations
- `ASC_KEY_ID` — the key identifier
- `ASC_PRIVATE_KEY_PATH` — absolute path to the `.p8` file

## Base URL

`https://api.appstoreconnect.apple.com`

## Request Pattern

```bash
curl -s -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  "https://api.appstoreconnect.apple.com/v1/..."
```

## Error Handling

All errors return:
```json
{
  "errors": [{
    "status": "409",
    "code": "ENTITY_ERROR.ATTRIBUTE.INVALID",
    "detail": "The actual useful error message is here"
  }]
}
```

**Always read the `detail` field** — it tells you exactly what's wrong.

Common status codes:
- 401: JWT expired or invalid — regenerate
- 403: API key lacks permission — check role (needs Admin)
- 404: Resource not found
- 405: Wrong HTTP method or endpoint path (e.g., POST to a list-only endpoint)
- 409: Entity error — read `detail` for specifics
- 429: Rate limited — wait 60s, retry (max 3)

## Type String Convention

All type strings in request bodies are **plural camelCase**: `appInfoLocalizations`, `appStoreVersionLocalizations`, `ageRatingDeclarations`, `appStoreReviewDetails`, `appScreenshotSets`, `appScreenshots`, `appCategories`, `subscriptionGroups`, `subscriptions`, `subscriptionPrices`.

## Hard-Won Lessons

These were discovered through live API failures. Do not skip.

1. **JWT: Use PyJWT, never openssl.** openssl dgst produces DER-encoded signatures incompatible with JWT ES256.
2. **Field casing matters.** The API uses camelCase (e.g., `productId` not `productID`, `familySharable` not `familyShareable`). Wrong casing returns "unknown attribute" errors.
3. **Subscription group creation:** `POST /v1/subscriptionGroups` (not `/v1/apps/{id}/subscriptionGroups` — that's 405).
4. **Availability before pricing.** Subscription prices fail with `ENTITY_ERROR.RELATIONSHIP.INVALID` if availability isn't set first.
5. **Starting prices have no startDate.** Omit the `attributes` block entirely. Future price changes need `startDate` at least 2 days out.
6. **Subscription description max 55 characters.** App listing description max 4000. Keywords max 100.
7. **Promo offer duration must match subscription period.** Annual subs only accept `ONE_YEAR` for `PAY_AS_YOU_GO`.
8. **Promo offers require inline prices** via `included` array with `subscriptionPromotionalOfferPrices` type.
9. **Price point IDs are opaque base64 strings.** Don't decode — match by `customerPrice`. Paginate (200/page).
10. **Categories are relationships, not attributes.** Set via `PATCH /v1/appInfos/{id}` with `primaryCategory` relationship, not attribute.
11. **Privacy labels have NO REST API.** Only `privacyPolicyUrl` and `privacyChoicesUrl` on `appInfoLocalizations` are available. Nutrition labels are web UI / Transporter only.
12. **Age rating: no create, only PATCH.** Auto-created with appInfo. Use `ageRatingOverrideV2` (not deprecated `ageRatingOverride`).
13. **Name: 30 chars max. Subtitle: 30 chars max.** Server-enforced, not in OpenAPI spec.
14. **`promotionalText` is the only field updatable without a new version submission.**

## Character Limits

| Resource | Field | Max Chars |
|---|---|---|
| App Info Localization | `name` | 30 |
| App Info Localization | `subtitle` | 30 |
| Version Localization | `description` | 4000 |
| Version Localization | `keywords` | 100 (comma-separated string) |
| Version Localization | `whatsNew` | 4000 |
| Version Localization | `promotionalText` | 170 |
| Subscription Localization | `description` | 55 |
| Review Details | `notes` | 4000 |

## Rate Limiting

Max ~100 requests/minute. On 429:
1. Wait 60 seconds
2. Retry with fresh JWT (may have expired)
3. Max 3 retries per endpoint
4. If still failing, stop and report

## Self-Healing Rule

When an API call fails: (1) fix the approach, (2) update the relevant skill's reference doc with the correct pattern and why, (3) continue. The skill should get smarter with every use.
