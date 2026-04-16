---
name: storekit-iac
description: "Infrastructure-as-Code for App Store Connect in-app purchases. Reads appstore/products.yml, diffs against live state, and applies changes. Modes: plan (default), apply, generate-storekit."
allowed-tools: Bash(*) Read Write Edit Glob Grep
argument-hint: "[plan|apply|generate-storekit]"
---

# StoreKit IaC — App Store Connect Product Management

Manage App Store Connect in-app purchases declaratively from `appstore/products.yml`.

## Reference

Load these before starting:
- [Shared ASC API](../shared/asc-api.md) — JWT auth, error handling, rate limiting, common gotchas
- [API Reference](api-reference.md) — Subscription-specific endpoints
- [StoreKit Format](storekit-format.md) — .storekit configuration file JSON schema

**Note:** For pushing subscriptions to App Store Connect, use `/appstore-iac apply` instead — it includes subscription sync as part of the full push. This skill's `apply` mode still works standalone but `appstore-iac` is the unified command.

## Modes

Parse the argument to determine mode:
- No argument or `plan` → **Plan mode** (default)
- `apply` → **Apply mode**
- `generate-storekit` → **Generate StoreKit mode**

---

## Hard-Won Lessons (read before every apply)

These were discovered through live API failures. Do not skip.

1. **JWT: Use PyJWT, never openssl.** `openssl dgst` produces DER-encoded signatures. JWT ES256 requires raw R||S concatenation. PyJWT handles this correctly. Requires `pip3 install PyJWT cryptography`.
2. **Field name is `productId`** (camelCase), NOT `productID`. The API returns a confusing error about "unknown attribute" if you get the casing wrong.
3. **Create groups at `/v1/subscriptionGroups`**, not `/v1/apps/{id}/subscriptionGroups` (405 error).
4. **Availability MUST be set before pricing.** `POST /v1/subscriptionPrices` returns `ENTITY_ERROR.RELATIONSHIP.INVALID` on the price point if no `subscriptionAvailability` exists yet.
5. **Starting price has no `startDate`.** Omit the `attributes` block entirely for the first price. Future price changes require `startDate` at least 2 days out.
6. **Subscription description max 55 characters.** Longer descriptions get `ENTITY_ERROR.ATTRIBUTE.INVALID.TOO_LONG`. Validate before sending.
7. **Promo offer duration must match subscription period.** For annual subs, only `ONE_YEAR` works with `PAY_AS_YOU_GO`. Monthly-duration offers on annual subs are rejected silently.
8. **Promo offers require inline prices.** Use the `included` array with `subscriptionPromotionalOfferPrices` type. Without it: `ENTITY_ERROR.RELATIONSHIP.REQUIRED`.
9. **Price point IDs are base64-encoded JSON.** They look like `eyJz...ifQ` and are opaque — don't decode them, just match by `customerPrice`. Paginate (200/page) to find higher price tiers.
10. **Review notes via PATCH.** Update `reviewNote` attribute on the subscription resource directly: `PATCH /v1/subscriptions/{id}`.

---

## Environment Setup

Before any API call, verify credentials are available:

```bash
echo "Issuer: ${ASC_ISSUER_ID:?Missing ASC_ISSUER_ID}"
echo "Key ID: ${ASC_KEY_ID:?Missing ASC_KEY_ID}"
test -f "$ASC_PRIVATE_KEY_PATH" && echo "Key file: OK" || echo "ERROR: .p8 not found at $ASC_PRIVATE_KEY_PATH"
```

If any variable is missing, tell the user to configure them:
1. Go to App Store Connect > Users and Access > Integrations > App Store Connect API
2. Generate an API key with Admin role
3. Download the `.p8` file (only downloadable once)
4. Set env vars in Claude Code settings (`~/.claude/settings.json` under `env`):
   - `ASC_ISSUER_ID` — the issuer ID from the API keys page
   - `ASC_KEY_ID` — the key identifier
   - `ASC_PRIVATE_KEY_PATH` — absolute path to the `.p8` file

---

## JWT Generation

Use PyJWT for all API calls. Generate fresh tokens as needed (20-min expiry).

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

Use in requests:
```bash
curl -s -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" ...
```

---

## Plan Mode (default)

**Goal:** Show what would change without making any mutations.

### Step 1: Read the config

Read `appstore/products.yml` and parse the YAML. Extract:
- `app_id`
- All subscription groups and their products
- Current wave → which territories are active
- Localizations for active wave locales
- Introductory and promotional offers

### Step 2: Generate JWT and fetch current state

Generate JWT (see above), then fetch:

```bash
# Subscription groups
curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/subscriptionGroups"

# For each group → subscriptions
curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/subscriptionGroups/$GROUP_ID/subscriptions"

# For each subscription → localizations, promo offers, availability
curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/subscriptions/$SUB_ID/subscriptionLocalizations"

curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/subscriptions/$SUB_ID/promotionalOffers"

curl -s -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/subscriptions/$SUB_ID/subscriptionAvailability?include=availableTerritories"
```

### Step 3: Diff and present

Compare desired state (YAML) against current state (API responses):

```
StoreKit IaC Plan — {app_name}
─────────────────────────

Subscription Group: "{group_name}"
  + CREATE {product_id} ({duration}, ${price})
  ~ UPDATE {product_id} field: old → new
  = {product_id} ({duration}, ${price})              # unchanged
  - DELETE {product_id}                              # in API but not in YAML

Availability (wave {n}):
  + ADD storefront: {territory}
  = {territory}

Localizations:
  + ADD {locale} for {product_id}
  ~ UPDATE {locale} for {product_id}: name changed

Introductory Offers:
  + CREATE free_trial P1W on {product_id}

Promotional Offers:
  + CREATE {offer_id} ({type}, {periods}x ${price})

{unchanged} unchanged · {create} to create · {update} to update · {delete} to delete
```

If there are deletions, warn: `WARNING: {n} items will be deleted. These cannot be undone.`

Do NOT proceed to apply. Plan output is the final result.

---

## Apply Mode

### Step 1: Run plan first

Execute the full plan mode. Show the diff to the user.

### Step 2: Confirm with user

Ask: "Apply these changes? This will modify your App Store Connect configuration."

If deletions exist: "WARNING: This includes {n} destructive changes that cannot be undone."

Wait for user confirmation.

### Step 3: Execute changes in dependency order

**This order is critical. Steps cannot be reordered.**

1. **Create subscription groups** (if new)
   - `POST /v1/subscriptionGroups` (NOT `/v1/apps/{id}/subscriptionGroups`)
   - Body: `referenceName` + app relationship

2. **Create subscriptions** within groups (if new)
   - `POST /v1/subscriptions`
   - Use `productId` (camelCase!), `subscriptionPeriod`, `groupLevel`, `familySharable`
   - Duration mapping: P1M→ONE_MONTH, P1Y→ONE_YEAR, etc.

3. **Create/update localizations**
   - `POST /v1/subscriptionLocalizations`
   - Fields: `name`, `description` (max 55 chars!), `locale`
   - Only push locales relevant to `current_wave`

4. **Set territory availability** (MUST be before pricing)
   - `POST /v1/subscriptionAvailabilities`
   - Include `availableInNewTerritories: false` for phased rollout
   - Territory data: `[{ "type": "territories", "id": "USA" }]`

5. **Set prices**
   - First, find price point IDs: `GET /v1/subscriptions/{id}/pricePoints?filter[territory]=USA&limit=200`
   - Match `attributes.customerPrice` to desired price. Paginate if needed.
   - `POST /v1/subscriptionPrices` — omit `attributes` block entirely for starting price
   - Only `relationships` with `subscription` and `subscriptionPricePoint`

6. **Create introductory offers**
   - `POST /v1/subscriptionIntroductoryOffers`
   - Fields: `duration`, `offerMode` (FREE_TRIAL/PAY_AS_YOU_GO/PAY_UP_FRONT), `numberOfPeriods`
   - Include `territory` relationship

7. **Create promotional offers**
   - `POST /v1/subscriptionPromotionalOffers`
   - Duration MUST match subscription period (annual → ONE_YEAR only for PAY_AS_YOU_GO)
   - MUST include prices via `included` array with `subscriptionPromotionalOfferPrices`

8. **Set review notes**
   - `PATCH /v1/subscriptions/{id}` with `reviewNote` attribute
   - Max 4000 characters. Include: what the subscription unlocks, how to trigger the paywall, sandbox testing instructions.

### Step 4: Error handling

After each API call:
- 2xx: log success, continue
- 409 ENTITY_ERROR: read the `detail` field carefully — it often tells you exactly what's wrong (casing, missing dependency, invalid value)
- 409 conflict (resource exists): fetch and compare. Skip if matching, PATCH if different.
- 429: wait 60 seconds, retry (max 3)
- 4xx/5xx: log error, stop, report to user

### Step 5: Verify

Run plan mode again. The diff should show 0 changes. Report any drift.

### Step 6: Generate .storekit if enabled

If `storekit_config.enabled` is true, run generate-storekit to keep local config in sync.

---

## Generate StoreKit Mode

**Goal:** Create or update the `.storekit` configuration file from products.yml. No API calls — purely local.

### Step 1: Read products.yml

Parse the YAML config.

### Step 2: Read existing .storekit (if any)

If a `.storekit` file already exists at the output path, read it and extract existing UUIDs. Map them by `productID` and `offerID` so they are preserved across regenerations.

### Step 3: Generate .storekit JSON

Follow the schema in storekit-format.md. Key rules:

- If UUIDs were extracted from an existing file, reuse them for matching entities
- For new entities, generate UUIDs with `uuidgen`
- Annual subscription gets `groupNumber: 1` (higher tier), monthly gets `groupNumber: 2`
- Convert locale format: `en-US` → `en_US`
- `displayPrice` is a string: `"6.99"` not `6.99`
- Include ALL localizations from the YAML (not just current wave)
- Set `_applicationInternalID` to the `app_id` from products.yml
- Set `_developerTeamID` from the project's DEVELOPMENT_TEAM
- Set version to `{ "major": 4, "minor": 0 }`

### Step 4: Write the file

Write JSON to the path in `storekit_config.output` (default: `Udana.storekit`).
Format with 2-space indentation and Xcode-style spacing (space before colon in keys).

### Step 5: Verify project.yml

Check that `project.yml` has `storeKitConfiguration` in the scheme's `run` and `test` sections.

### Step 6: Report

```
Generated {output_path}
  Subscription Groups: {n}
  Products: {n}
  Promotional Offers: {n}
  Localizations: {n} locales

Ready for Xcode sandbox testing.
```

---

## Safety Rules

1. **Never modify products.yml.** It is read-only input.
2. **Never log .p8 key contents or JWT tokens.** Log only key ID and issuer ID.
3. **Plan is always default.** Ambiguous arguments → plan.
4. **Confirm before apply.** Always show plan diff and wait for user confirmation.
5. **Destructive changes need extra confirmation.** Deletions get a warning.
6. **Rate limiting.** 429 → wait 60s, max 3 retries per endpoint.
7. **Product ID validation.** Before apply, verify YAML product IDs match `StoreKitService.swift`. Warn on mismatches.
8. **Description length validation.** Check all localization descriptions are ≤ 55 chars before sending. Fail fast with a clear message if any exceed.
9. **Self-healing.** When an API call fails, read the error detail, fix the approach, and update this skill's reference docs with the learning so future runs don't hit the same issue.
