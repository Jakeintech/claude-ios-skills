# App Store Connect API Reference for StoreKit IaC

## Authentication

Generate a JWT signed with ES256 using the `.p8` private key.

### JWT Header
```json
{
  "alg": "ES256",
  "kid": "$ASC_KEY_ID",
  "typ": "JWT"
}
```

### JWT Payload
```json
{
  "iss": "$ASC_ISSUER_ID",
  "iat": <current_unix_timestamp>,
  "exp": <current_unix_timestamp + 1200>,
  "aud": "appstoreconnect-v1"
}
```

### Generate JWT with Python (PyJWT)

openssl dgst produces DER-encoded signatures but JWT ES256 requires raw R||S format. Use PyJWT instead:

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

### Use in requests

```bash
curl -H "Authorization: Bearer $JWT" \
     -H "Content-Type: application/json" \
     "https://api.appstoreconnect.apple.com/v1/..."
```

## Base URL

`https://api.appstoreconnect.apple.com`

## Endpoints

### List Subscription Groups

```
GET /v1/apps/{app_id}/subscriptionGroups
```

Response includes `data[].id` (group ID) and `data[].attributes.referenceName`.

### Create Subscription Group

```
POST /v1/subscriptionGroups
```

```json
{
  "data": {
    "type": "subscriptionGroups",
    "attributes": {
      "referenceName": "Udana Pro"
    },
    "relationships": {
      "app": {
        "data": { "type": "apps", "id": "{app_id}" }
      }
    }
  }
}
```

### List Subscriptions in Group

```
GET /v1/subscriptionGroups/{group_id}/subscriptions
```

### Create Subscription

```
POST /v1/subscriptions
```

```json
{
  "data": {
    "type": "subscriptions",
    "attributes": {
      "name": "Udana Pro Monthly",
      "productId": "com.udana.pro.monthly",
      "subscriptionPeriod": "ONE_MONTH",
      "reviewNote": "",
      "familySharable": false
    },
    "relationships": {
      "group": {
        "data": { "type": "subscriptionGroups", "id": "{group_id}" }
      }
    }
  }
}
```

**subscriptionPeriod values:** `ONE_WEEK`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`

**Duration mapping from ISO 8601:**
| YAML | API |
|------|-----|
| P1W | ONE_WEEK |
| P1M | ONE_MONTH |
| P2M | TWO_MONTHS |
| P3M | THREE_MONTHS |
| P6M | SIX_MONTHS |
| P1Y | ONE_YEAR |

### Set Subscription Price

**IMPORTANT:** Availability MUST be set before pricing. Without it, price point IDs are rejected with `ENTITY_ERROR.RELATIONSHIP.INVALID`.

**Starting price (no existing price):** Omit the `attributes` block entirely.

```
POST /v1/subscriptionPrices
```

```json
{
  "data": {
    "type": "subscriptionPrices",
    "relationships": {
      "subscription": {
        "data": { "type": "subscriptions", "id": "{subscription_id}" }
      },
      "subscriptionPricePoint": {
        "data": { "type": "subscriptionPricePoints", "id": "{price_point_id}" }
      }
    }
  }
}
```

**Future price change:** Include `startDate` at least 2 days in the future.

```json
{
  "data": {
    "type": "subscriptionPrices",
    "attributes": {
      "startDate": "2026-05-01"
    },
    "relationships": { ... }
  }
}
```

**Finding price point IDs:** Paginate — there are 800+ price points per subscription.

```
GET /v1/subscriptions/{id}/pricePoints?filter[territory]=USA&limit=200
```

Match `attributes.customerPrice` to desired price. Price point IDs are base64-encoded opaque strings (e.g., `eyJz...ifQ`).

### Create Introductory Offer

```
POST /v1/subscriptionIntroductoryOffers
```

```json
{
  "data": {
    "type": "subscriptionIntroductoryOffers",
    "attributes": {
      "duration": "ONE_WEEK",
      "offerMode": "FREE_TRIAL",
      "numberOfPeriods": 1,
      "startDate": null,
      "endDate": null
    },
    "relationships": {
      "subscription": {
        "data": { "type": "subscriptions", "id": "{subscription_id}" }
      },
      "territory": {
        "data": { "type": "territories", "id": "USA" }
      }
    }
  }
}
```

**offerMode values:** `FREE_TRIAL`, `PAY_AS_YOU_GO`, `PAY_UP_FRONT`

**duration values:** `THREE_DAYS`, `ONE_WEEK`, `TWO_WEEKS`, `ONE_MONTH`, `TWO_MONTHS`, `THREE_MONTHS`, `SIX_MONTHS`, `ONE_YEAR`

### Create Promotional Offer

**IMPORTANT:** Promo offer duration must match the subscription period. For annual subs, only `ONE_YEAR` with `numberOfPeriods: 1` works for `PAY_AS_YOU_GO`. For monthly subs, `ONE_MONTH` with various periods works. The API silently rejects mismatched durations.

**IMPORTANT:** Prices must be included inline via `included` array with `subscriptionPromotionalOfferPrices`. The offer will be rejected without prices.

```
POST /v1/subscriptionPromotionalOffers
```

```json
{
  "data": {
    "type": "subscriptionPromotionalOffers",
    "attributes": {
      "name": "comeback_30",
      "offerCode": "comeback_30",
      "duration": "ONE_YEAR",
      "offerMode": "PAY_AS_YOU_GO",
      "numberOfPeriods": 1
    },
    "relationships": {
      "subscription": {
        "data": { "type": "subscriptions", "id": "{subscription_id}" }
      },
      "prices": {
        "data": [
          { "type": "subscriptionPromotionalOfferPrices", "id": "${placeholder}" }
        ]
      }
    }
  },
  "included": [
    {
      "type": "subscriptionPromotionalOfferPrices",
      "id": "${placeholder}",
      "relationships": {
        "subscriptionPricePoint": {
          "data": { "type": "subscriptionPricePoints", "id": "{price_point_id}" }
        },
        "territory": {
          "data": { "type": "territories", "id": "USA" }
        }
      }
    }
  ]
}
```

### Set Promotional Offer Price

After creating a promotional offer, set its price:

```
POST /v1/subscriptionPromotionalOfferPrices
```

```json
{
  "data": {
    "type": "subscriptionPromotionalOfferPrices",
    "relationships": {
      "subscriptionPricePoint": {
        "data": { "type": "subscriptionPricePoints", "id": "{price_point_id}" }
      },
      "territory": {
        "data": { "type": "territories", "id": "USA" }
      }
    }
  }
}
```

**IMPORTANT:** Subscription description has a 55 character maximum. Validate before sending.

### Create Subscription Localization

```
POST /v1/subscriptionLocalizations
```

```json
{
  "data": {
    "type": "subscriptionLocalizations",
    "attributes": {
      "name": "Udana Pro Monthly",
      "description": "Unlimited class recordings and full analytics",
      "locale": "en-US"
    },
    "relationships": {
      "subscription": {
        "data": { "type": "subscriptions", "id": "{subscription_id}" }
      }
    }
  }
}
```

### Update Subscription Localization

```
PATCH /v1/subscriptionLocalizations/{localization_id}
```

### Set Territory Availability

```
GET /v1/apps/{app_id}/appAvailability
POST /v1/appAvailabilities
```

Territory codes use ISO 3166-1 alpha-3 (e.g., USA, CAN, GBR, AUS).

### List Promotional Offers

```
GET /v1/subscriptions/{subscription_id}/promotionalOffers
```

### Delete Promotional Offer

```
DELETE /v1/subscriptionPromotionalOffers/{offer_id}
```

## Error Handling

All errors return:
```json
{
  "errors": [
    {
      "status": "409",
      "code": "ENTITY_ERROR.RELATIONSHIP.INVALID",
      "title": "...",
      "detail": "..."
    }
  ]
}
```

Common status codes:
- 401: JWT expired or invalid
- 403: API key lacks permission
- 404: Resource not found
- 409: Conflict (e.g., product ID already exists)
- 429: Rate limited (max 100 req/min, back off and retry)
