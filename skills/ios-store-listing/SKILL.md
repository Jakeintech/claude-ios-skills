---
name: ios-store-listing
description: Generate and optimize App Store listing metadata — app name, subtitle, description, keywords, promotional text, What's New, categories. Uses 3 parallel subagents for marketing copy, brand voice, and ASO keyword research grounded in live App Store competitor data.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep Agent WebSearch
---

# App Store Listing

Generates optimized App Store listing metadata using parallel subagents:

- **marketing-copywriter** — hook, description, promo text, what's-new
- **brand-voice** — tone-checks and adjusts copywriter output against brand book
- **aso-specialist** — live WebSearch competitor scan + keywords + title/subtitle variants

Synthesizes their outputs into `appstore/listing.json`.

## Fields produced

| Field | Constraint | Source in synthesis |
|-------|-----------|---------------------|
| name | 30 chars | `app-info.json.name` (preserved; aso suggestions are advisory) |
| subtitle | 30 chars | `aso.subtitle_variants[0]` or `app-info.subtitle` |
| promotionalText | 170 chars | `brand-voice.adjusted_promotionalText` |
| description | 4000 chars | `brand-voice.adjusted_description` |
| keywords | 100 chars | `aso.keywords` |
| whatsNew | 4000 chars | `brand-voice.adjusted_whatsNew` |
| supportUrl | reachable URL | `app-info.support_url` |
| marketingUrl | reachable URL | `app-info.marketing_url` |
| copyright | auto | `{year} {developer_name}` |
| primaryCategory | Apple ID | `app-info.categories[0]` |
| secondaryCategory | Apple ID | `app-info.categories[1]` |

## Process

### 1. Validate inputs

```bash
# Required files
for f in "docs/product-vision/00-product-bounds.md" "appstore/app-info.json" "CLAUDE.md"; do
  test -f "$f" || { echo "MISSING: $f"; exit 1; }
done
```

```python
import json
info = json.load(open("appstore/app-info.json"))
assert info.get("app_id"), "app_id missing"
assert info.get("name"), "name missing"
# Support both flat keys (primaryCategory/secondaryCategory) and legacy categories[] array
primary_cat = info.get("primaryCategory") or (info.get("categories") or [None])[0]
assert primary_cat, "primaryCategory (or categories[0]) missing"
```

If `app-info.json` lacks `marketing_url` or `support_url`, warn the user: those fields in `listing.json` will be empty until `/ios-site init` runs.

### 2. Gather sources

```bash
brand_book=$(cat docs/product-vision/00-product-bounds.md)
claude_md=$(cat CLAUDE.md)
app_info=$(cat appstore/app-info.json)
existing_listing=$(cat appstore/listing.json 2>/dev/null || echo "{}")

# Git log since last tag (fallback: last 30 commits)
git_log=$(git log --oneline "$(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~30)..HEAD")
```

### 3. Dispatch subagents in parallel

Make ONE message with two `Agent` tool calls (the marketing-copywriter → brand-voice is a serial chain; aso is independent).

**Chain 1 (sequential):** marketing-copywriter → brand-voice.
Prompt the Agent tool: "You are running marketing-copywriter per skills/ios-store-listing/agents/marketing-copywriter.md. Here are inputs... Then take your output and run brand-voice per skills/ios-store-listing/agents/brand-voice.md with the brand book. Return final brand-voice JSON."

**Chain 2 (independent):** aso-specialist with WebSearch access per skills/ios-store-listing/agents/aso-specialist.md.

Both chains run in parallel (one message, two Agent calls). Each chain is one Agent dispatch.

Agent inputs should include the file contents literally (not paths) so subagents don't need filesystem access.

### 4. Wait and parse

- If any chain fails to return valid JSON, retry that chain ONCE with a stricter schema prompt.
- Second failure → abort, print raw output, exit non-zero. Never fall back to heuristic synthesis.

### 5. Synthesis (pure logic)

```python
import json, datetime

def truncate_at_sentence(s, limit):
    if len(s) <= limit:
        return s, False
    cut = s[:limit].rsplit(".", 1)[0] + "."
    if len(cut) < limit * 0.5:  # sentence boundary too far back
        cut = s[:limit-1].rstrip() + "…"
    return cut, True

def synthesize(copy, aso, app_info, year=2026, developer="Jake Williams"):
    warnings = []
    truncations = []

    # Pull adjusted copy from brand-voice
    desc, t = truncate_at_sentence(copy["adjusted_description"], 4000)
    if t: truncations.append(("description", len(copy["adjusted_description"]), 4000))
    promo, t = truncate_at_sentence(copy["adjusted_promotionalText"], 170)
    if t: truncations.append(("promotionalText", len(copy["adjusted_promotionalText"]), 170))
    whats_new, t = truncate_at_sentence(copy["adjusted_whatsNew"], 4000)
    if t: truncations.append(("whatsNew", len(copy["adjusted_whatsNew"]), 4000))

    # ASO outputs
    keywords = aso["keywords"][:100]  # hard clip
    if aso["competitor_scan"] == "failed":
        warnings.append(f"⚠ ASO scan failed ({aso['competitor_scan_reason']}) — keywords from brand book only")

    # Subtitle: aso variant if valid, else fall back
    subtitle = aso["subtitle_variants"][0] if aso.get("subtitle_variants") and len(aso["subtitle_variants"][0]) <= 30 else app_info.get("subtitle", "")

    # Support both flat keys and legacy array; flat keys are canonical going forward
    primary_cat = app_info.get("primaryCategory") or (app_info.get("categories") or [None])[0]
    secondary_cat = app_info.get("secondaryCategory") or (app_info.get("categories") or [None, None])[1]

    listing = {
        "name": app_info["name"],  # never auto-rename
        "subtitle": subtitle,
        "promotionalText": promo,
        "description": desc,
        "keywords": keywords,
        "whatsNew": whats_new,
        "supportUrl": app_info.get("support_url", ""),
        "marketingUrl": app_info.get("marketing_url", ""),
        "copyright": f"{year} {developer}",
        "primaryCategory": primary_cat,
        "secondaryCategory": secondary_cat,
    }
    return listing, warnings, truncations, copy.get("tone_violations", []), aso.get("title_variants", [])
```

### 6. Validation

```python
assert len(listing["name"]) <= 30
assert len(listing["subtitle"]) <= 30
assert len(listing["promotionalText"]) <= 170
assert len(listing["description"]) <= 4000
assert len(listing["keywords"]) <= 100
assert len(listing["whatsNew"]) <= 4000
assert listing["primaryCategory"], "primaryCategory required"
# JSON round-trip
json.loads(json.dumps(listing))
```

### 7. Present for review

Print each field with character count. Highlight truncations with `⚠`. Show:
- ASO warnings (scan failed, etc.)
- Title-variant suggestions from ASO (advisory): "Consider renaming in app-info.json: {variants}"
- Tone violations from brand-voice: "Copywriter missed these tone notes: {violations}"

Ask: "Write this to `appstore/listing.json`? [y/N]"

### 8. Write

On approval:

```python
with open("appstore/listing.json", "w") as f:
    json.dump(listing, f, indent=2)
```

If existing file's contents are byte-identical to new output, skip write and report "no changes."

### 9. Next step

Print:
```
Listing written to appstore/listing.json. Next:
  /ios-site init        — scaffold the marketing/legal site (if not done yet)
  /appstore-iac plan    — preview the full App Store sync
  /appstore-iac apply   — push everything live
```

## User override

Edit `appstore/listing.json` directly. Re-running the skill regenerates all fields — if the user wants to lock a field, they can revert after regeneration. (v1 simplification: the skill always presents a diff for user approval before writing, so user edits are never silently overwritten.)

## Localization

For additional locales, run `/ios-localize` (separate skill). That produces `appstore/listing-{locale}.json` files that `appstore-iac` uploads.
