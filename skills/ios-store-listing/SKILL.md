---
name: ios-store-listing
description: Generate and optimize App Store listing metadata — app name, subtitle, description, keywords, promotional text, What's New, categories. ASO-optimized. Uploads via asc CLI.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# App Store Listing

Generate optimized App Store metadata from your brand book and app content.

## Fields

| Field | Source | Constraint |
|-------|--------|-----------|
| App Name | Brand book North Star | 30 chars max |
| Subtitle | Brand book + key features | 30 chars max |
| Promotional Text | Brand book + current version highlights | 170 chars, updatable without review |
| Description | Brand book pillars + epics + app capabilities | 4000 chars max |
| Keywords | Brand book + category analysis | 100 chars comma-separated |
| What's New | Git log since last version tag | 4000 chars max |
| Support URL | Project config or user input | Must be reachable |
| Marketing URL | Project config or user input | Must be reachable |
| Copyright | Current year + developer name | Auto-generated |
| Primary Category | Brand book domain | Apple category ID |
| Secondary Category | Brand book domain | Apple category ID |

## Process

### 1. Gather Sources

- Read `docs/product-vision/00-product-bounds.md` for North Star, pillars, epics, design identity
- Read `CLAUDE.md` for app description and features
- Run `git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~20)..HEAD` for recent changes
- Check if `appstore/listing.json` already exists — load existing values as defaults

### 2. Generate Metadata

For each field:

**App Name:** Extract from brand book North Star. Keep under 30 chars. No generic terms.

**Subtitle:** Distill the value proposition into 30 chars. Focus on what makes this app unique.

**Description:** Structure as:
- Hook paragraph (what the app does, why it's special)
- Feature highlights (bulleted or paragraph, from epics)
- Social proof or differentiators
- Call to action
Stay under 4000 chars. Write for humans, not algorithms.

**Keywords:** 
- Extract key terms from brand book, epics, and feature descriptions
- DO NOT duplicate words already in the app name or subtitle (Apple indexes those separately)
- Prefer single words over phrases (phrases waste character budget)
- Include synonyms and related terms
- Comma-separated, no spaces after commas, exactly 100 chars
- Prioritize: category-relevant terms > feature terms > general terms

**Promotional Text:** Short, punchy summary of the current version's highlights. Can be updated without app review.

**What's New:** Parse git log into user-facing release notes. Group by feature, not by commit. Keep it scannable.

### 3. Output

Write all fields to `appstore/listing.json`:

```json
{
  "name": "App Name",
  "subtitle": "Your subtitle here",
  "promotionalText": "Promotional text here",
  "description": "Full description...",
  "keywords": "keyword1,keyword2,keyword3",
  "whatsNew": "What's new in this version...",
  "supportUrl": "https://...",
  "marketingUrl": "https://...",
  "copyright": "2026 Developer Name",
  "primaryCategory": "LIFESTYLE",
  "secondaryCategory": "HEALTH_AND_FITNESS"
}
```

### 4. Present for Review

Show the user each field with its character count and constraint. Ask for approval or edits before uploading.

### 5. Upload

Upload to App Store Connect via `asc`:

```bash
# Update app info
asc apps update --app-id $APP_ID --name "App Name" --subtitle "Subtitle"

# Update version metadata
asc versions update --app-id $APP_ID --description "..." --keywords "..." --promotional-text "..." --whats-new "..."
```

If `asc` is not configured, provide the generated `listing.json` and instructions for manual entry or guide through browser via computer-use MCP.

### 6. Localization (Optional)

If the user requests additional languages:
- Generate translated/adapted versions of all fields
- Store in `appstore/listing-{locale}.json` (e.g., `listing-es.json`, `listing-ja.json`)
- Upload each locale via `asc`

### User Override

Edit `appstore/listing.json` directly. Re-running the skill reads existing values and only regenerates fields that are empty or explicitly cleared.
