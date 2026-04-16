# StoreKit Configuration File Format

Reference for generating `.storekit` files (Xcode StoreKit Configuration, version 4.0).

## Top-Level Structure

```json
{
  "identifier" : "<UUID>",
  "nonRenewingSubscriptions" : [],
  "products" : [],
  "settings" : { ... },
  "subscriptionGroups" : [ ... ],
  "version" : { "major" : 4, "minor" : 0 }
}
```

## Settings Block

Always include this settings block. Replace `_developerTeamID` with the project's team ID.

```json
"settings" : {
  "_applicationInternalID" : "0",
  "_developerTeamID" : "YOUR_TEAM_ID",
  "_failTransactionsEnabled" : false,
  "_locale" : "en_US",
  "_storefront" : "USA",
  "_storeKitErrors" : [
    { "current" : null, "enabled" : false, "name" : "Load Products" },
    { "current" : null, "enabled" : false, "name" : "Purchase" },
    { "current" : null, "enabled" : false, "name" : "Verification" },
    { "current" : null, "enabled" : false, "name" : "App Store Sync" },
    { "current" : null, "enabled" : false, "name" : "Subscription Status" },
    { "current" : null, "enabled" : false, "name" : "App Transaction" },
    { "current" : null, "enabled" : false, "name" : "Manage Subscriptions Sheet" },
    { "current" : null, "enabled" : false, "name" : "Offer Code Redeem Sheet" },
    { "current" : null, "enabled" : false, "name" : "Transaction Manager" }
  ]
}
```

## Subscription Group

```json
{
  "id" : "<UUID>",
  "localizations" : [],
  "name" : "Group Display Name",
  "subscriptions" : [ ... ]
}
```

## Subscription

```json
{
  "adHocOffers" : [],
  "codeOffers" : [],
  "displayPrice" : "6.99",
  "familyShareable" : false,
  "groupNumber" : 1,
  "internalID" : "<UUID>",
  "introductoryOffer" : null,
  "localizations" : [
    {
      "description" : "Product description",
      "displayName" : "Product Name",
      "locale" : "en_US"
    }
  ],
  "productID" : "com.example.product.id",
  "recurringSubscriptionPeriod" : "P1M",
  "referenceName" : "Display Name",
  "subscriptionGroupID" : "<matches parent group id>",
  "type" : "RecurringSubscription"
}
```

**recurringSubscriptionPeriod:** ISO 8601 duration — `P1W`, `P1M`, `P2M`, `P3M`, `P6M`, `P1Y`

**groupNumber:** Rank within the group. Lower number = higher tier. Annual should be 1 (highest tier), monthly should be 2.

## Introductory Offer

```json
"introductoryOffer" : {
  "displayPrice" : "0",
  "internalID" : "<UUID>",
  "paymentMode" : "free",
  "subscriptionPeriod" : "P1W"
}
```

**paymentMode values:** `free` (free trial), `payAsYouGo`, `payUpFront`

For paid offers, set `displayPrice` to the offer price as a string.

## Promotional Offer (adHocOffers)

```json
{
  "displayPrice" : "2.99",
  "internalID" : "<UUID>",
  "numberOfPeriods" : 3,
  "offerID" : "comeback_30",
  "paymentMode" : "payAsYouGo",
  "referenceName" : "comeback_30",
  "subscriptionPeriod" : "P1M"
}
```

## Mapping from products.yml

| YAML field | .storekit field |
|---|---|
| `subscription_groups[].name` | `subscriptionGroups[].name` |
| `products[].id` | `subscriptions[].productID` |
| `products[].duration` | `subscriptions[].recurringSubscriptionPeriod` |
| `products[].base_price` | `subscriptions[].displayPrice` (string) |
| `localizations[locale][product_id].name` | `subscriptions[].localizations[].displayName` |
| `localizations[locale][product_id].description` | `subscriptions[].localizations[].description` |
| `products[].introductory_offer` | `subscriptions[].introductoryOffer` |
| `products[].promotional_offers[]` | `subscriptions[].adHocOffers[]` |

## UUID Generation

Generate stable UUIDs. Use `uuidgen` for each unique entity (group, subscription, offer). Once generated for a product, the UUID should remain the same across regenerations — do not randomize on each run.

## Locale Format

StoreKit config uses underscore locale format: `en_US`, `en_GB`. The products.yml uses hyphen format: `en-US`, `en-GB`. Convert hyphens to underscores when generating.
