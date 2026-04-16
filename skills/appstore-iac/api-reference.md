# App Store Connect API Reference — App Metadata

Endpoints for managing app information, versions, localizations, age rating, review details, screenshots, and subscriptions.

See [Shared ASC API](../shared/asc-api.md) for JWT auth, error handling, character limits, and rate limiting.

---

## App Information

### Get App Info

```
GET /v1/apps/{app_id}/appInfos
```

Returns `data[].id` (appInfoId). Follow `appInfoLocalizations` and `ageRatingDeclaration` relationships.

### Update App Info (categories)

Categories are **relationships**, not attributes.

```
PATCH /v1/appInfos/{appInfoId}
```

```json
{
  "data": {
    "type": "appInfos",
    "id": "{appInfoId}",
    "relationships": {
      "primaryCategory": {
        "data": { "type": "appCategories", "id": "HEALTH_AND_FITNESS" }
      },
      "secondaryCategory": {
        "data": { "type": "appCategories", "id": "MUSIC" }
      }
    }
  }
}
```

Category IDs are SCREAMING_SNAKE_CASE strings: `HEALTH_AND_FITNESS`, `MUSIC`, `SPORTS`, `LIFESTYLE`, `ENTERTAINMENT`, `EDUCATION`, `SOCIAL_NETWORKING`, `PHOTO_AND_VIDEO`, `PRODUCTIVITY`, `UTILITIES`, etc.

Subcategory relationships: `primarySubcategoryOne`, `primarySubcategoryTwo`, `secondarySubcategoryOne`, `secondarySubcategoryTwo`. Set to `null` to clear.

### Get App Info Localizations

```
GET /v1/appInfos/{appInfoId}/appInfoLocalizations
```

### Update App Info Localization (name, subtitle)

```
PATCH /v1/appInfoLocalizations/{locId}
```

```json
{
  "data": {
    "type": "appInfoLocalizations",
    "id": "{locId}",
    "attributes": {
      "name": "Udana",
      "subtitle": "Track Your Fitness Classes",
      "privacyPolicyUrl": "https://udana.app/privacy",
      "privacyChoicesUrl": null,
      "privacyPolicyText": null
    }
  }
}
```

- `name`: max 30 chars. Must match across localizations unless approved localized name.
- `subtitle`: max 30 chars. Nullable.
- `locale` is immutable after create.
- `privacyPolicyUrl` and `privacyChoicesUrl` are the ONLY privacy-related API fields. Nutrition labels are web UI only.

---

## App Store Versions

### List Versions

```
GET /v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS
```

Look for `appStoreState` of `PREPARE_FOR_SUBMISSION`, `DEVELOPER_REJECTED`, or `REJECTED`. That's the editable version.

### Get Version Localizations

```
GET /v1/appStoreVersions/{versionId}/appStoreVersionLocalizations
```

### Update Version Localization

```
PATCH /v1/appStoreVersionLocalizations/{locId}
```

```json
{
  "data": {
    "type": "appStoreVersionLocalizations",
    "id": "{locId}",
    "attributes": {
      "description": "...",
      "keywords": "fitness,class,music,playlist,workout",
      "whatsNew": "Initial release",
      "promotionalText": "Now with instructor cue detection",
      "supportUrl": "https://udana.app/support",
      "marketingUrl": "https://udana.app"
    }
  }
}
```

**Field limits:** description 4000, keywords 100 (comma-separated string NOT array), whatsNew 4000, promotionalText 170.

**`promotionalText`** is the only field updatable without a new version submission.

`locale` is immutable. Use `POST /v1/appStoreVersionLocalizations` to add new locales (requires `appStoreVersion` relationship).

---

## Age Rating Declaration

**No create endpoint** — auto-created with appInfo. PATCH only.

### Get Age Rating

```
GET /v1/appInfos/{appInfoId}/ageRatingDeclaration
```

### Update Age Rating

```
PATCH /v1/ageRatingDeclarations/{ageRatingId}
```

```json
{
  "data": {
    "type": "ageRatingDeclarations",
    "id": "{ageRatingId}",
    "attributes": {
      "violenceCartoonOrFantasy": "NONE",
      "violenceRealistic": "NONE",
      "violenceRealisticProlongedGraphicOrSadistic": "NONE",
      "profanityOrCrudeHumor": "NONE",
      "matureOrSuggestiveThemes": "NONE",
      "horrorOrFearThemes": "NONE",
      "medicalOrTreatmentInformation": "NONE",
      "alcoholTobaccoOrDrugUseOrReferences": "NONE",
      "gamblingSimulated": "NONE",
      "sexualContentOrNudity": "NONE",
      "sexualContentGraphicAndNudity": "NONE",
      "gambling": false,
      "unrestrictedWebAccess": false,
      "contests": "NONE",
      "healthOrWellnessTopics": true,
      "advertising": false,
      "lootBox": false,
      "messagingAndChat": false,
      "parentalControls": false,
      "userGeneratedContent": false
    }
  }
}
```

**Frequency/intensity enum values:** `NONE`, `INFREQUENT_OR_MILD`, `FREQUENT_OR_INTENSE`

**Boolean fields:** `gambling`, `unrestrictedWebAccess`, `advertising`, `lootBox`, `messagingAndChat`, `parentalControls`, `ageAssurance`, `userGeneratedContent`, `healthOrWellnessTopics`

**Mapping from age-rating.json:**
| age-rating.json key | API attribute |
|---|---|
| `cartoonOrFantasyViolence` | `violenceCartoonOrFantasy` |
| `realisticViolence` | `violenceRealistic` |
| `profanityOrCrudeHumor` | `profanityOrCrudeHumor` |
| `matureOrSuggestiveThemes` | `matureOrSuggestiveThemes` |
| `horrorOrFearThemes` | `horrorOrFearThemes` |
| `medicalTreatmentInformation` | `medicalOrTreatmentInformation` |
| `alcoholTobaccoDrugUse` | `alcoholTobaccoOrDrugUseOrReferences` |
| `simulatedGambling` | `gamblingSimulated` |
| `sexualContentOrNudity` | `sexualContentOrNudity` |
| `unrestrictedWebAccess` | `unrestrictedWebAccess` |
| `gamblingWithRealCurrency` | `gambling` |

Use `ageRatingOverrideV2` (not deprecated `ageRatingOverride`). Values: `NONE`, `NINE_PLUS`, `THIRTEEN_PLUS`, `SIXTEEN_PLUS`, `EIGHTEEN_PLUS`, `UNRATED`.

---

## Review Details

### Get Review Detail

```
GET /v1/appStoreVersions/{versionId}/appStoreReviewDetail
```

### Create Review Detail

```
POST /v1/appStoreReviewDetails
```

```json
{
  "data": {
    "type": "appStoreReviewDetails",
    "attributes": {
      "contactFirstName": "Jake",
      "contactLastName": "Williams",
      "contactEmail": "your@email.com",
      "contactPhone": "",
      "demoAccountName": null,
      "demoAccountPassword": null,
      "demoAccountRequired": false,
      "notes": "..."
    },
    "relationships": {
      "appStoreVersion": {
        "data": { "type": "appStoreVersions", "id": "{versionId}" }
      }
    }
  }
}
```

### Update Review Detail

```
PATCH /v1/appStoreReviewDetails/{reviewDetailId}
```

Same attributes, no relationship needed. `notes` max 4000 chars. `demoAccountRequired` is a boolean.

**Do NOT confuse with `betaAppReviewDetail`** (TestFlight) — different resource at `/v1/apps/{id}/betaAppReviewDetail`.

---

## Export Compliance

Set on the version directly:

```
PATCH /v1/appStoreVersions/{versionId}
```

```json
{
  "data": {
    "type": "appStoreVersions",
    "id": "{versionId}",
    "attributes": {
      "usesNonExemptEncryption": false
    }
  }
}
```

---

## App Availability

### Set App Availability

```
POST /v1/appAvailabilities
```

```json
{
  "data": {
    "type": "appAvailabilities",
    "attributes": {
      "availableInNewTerritories": true
    },
    "relationships": {
      "app": {
        "data": { "type": "apps", "id": "{app_id}" }
      },
      "availableTerritories": {
        "data": [
          { "type": "territories", "id": "USA" }
        ]
      }
    }
  }
}
```

For a free app, pricing is automatic — no price endpoint needed.

---

## Subscriptions

See [storekit-iac API Reference](../storekit-iac/api-reference.md) for subscription-specific endpoints. The appstore-iac skill imports and executes the same subscription logic.

Key endpoints:
- `POST /v1/subscriptionGroups` — create group
- `POST /v1/subscriptions` — create subscription (`productId` camelCase!)
- `POST /v1/subscriptionLocalizations` — description max 55 chars
- `POST /v1/subscriptionAvailabilities` — MUST be before pricing
- `POST /v1/subscriptionPrices` — omit attributes for starting price
- `POST /v1/subscriptionIntroductoryOffers` — free trials, pay-as-you-go
- `POST /v1/subscriptionPromotionalOffers` — duration must match sub period, prices inline via `included`

---

## Screenshots

See [Screenshot Upload](screenshot-upload.md) for the detailed 4-step flow.

### List Screenshot Sets

```
GET /v1/appStoreVersionLocalizations/{locId}/appScreenshotSets
```

### List Screenshots in Set

```
GET /v1/appScreenshotSets/{setId}/appScreenshots
```

### Delete Screenshot

```
DELETE /v1/appScreenshots/{screenshotId}
```

---

## Privacy Labels

**NO REST API.** Privacy nutrition labels can only be managed through:
- App Store Connect web UI
- Apple Transporter (XML-based)

The only privacy-related API fields are `privacyPolicyUrl`, `privacyChoicesUrl`, and `privacyPolicyText` on `appInfoLocalizations` — these set the privacy policy link, NOT the nutrition labels.

The `plan` output should flag privacy labels as a manual step.
