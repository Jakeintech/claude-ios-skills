---
name: ios-screenshots
description: Generate App Store screenshots for all required device sizes. Multi-stage pipeline — raw capture, framed, marketing shots, upload-ready. Intermediates stored at every stage for manual override.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# App Store Screenshots

Generate App Store-ready screenshots for all required device classes.

## Device Classes

Auto-detect supported platforms by reading `project.yml` targets and `supportedDestinations`:

| Device | Resolution (portrait) | Required? |
|--------|----------------------|-----------|
| iPhone 6.7" | 1290x2796 | Yes |
| iPhone 6.1" | 1179x2556 | Recommended |
| iPad 13" | 2064x2752 | Yes if iPad supported |
| iPad 11" | 1668x2388 | Recommended if iPad |
| Apple Watch Ultra | 410x502 | Yes if watchOS supported |
| Apple Watch Series | 396x484 | Recommended if watchOS |

## Stage 1: Raw Capture

1. Read `project.yml` to determine supported platforms
2. Read brand book (`docs/product-vision/00-product-bounds.md`) for "key screens" list
3. For each required device class:
   - Boot the appropriate simulator via iOS Simulator MCP
   - Build and deploy the app via XcodeBuildMCP
   - Navigate to each key screen
   - Capture raw PNG screenshot via iOS Simulator MCP
4. Store in `screenshots/raw/{device}/{screen-name}.png`

**Naming convention:**
- `screenshots/raw/iphone-6.7/home.png`
- `screenshots/raw/iphone-6.7/settings.png`
- `screenshots/raw/ipad-13/home.png`
- `screenshots/raw/watch-ultra/glance.png`

## Stage 2: Framed

1. For each raw screenshot:
   - Add device bezel/frame matching Apple's marketing device style
   - Use an HTML template rendered to PNG at the correct resolution:
     - Create a temporary HTML file with the device frame as CSS/SVG and the screenshot as the content
     - Render to PNG using a headless browser or the Playwright MCP
   - Alternatively, use ImageMagick (`convert`) to composite the screenshot onto a device frame template
2. Store in `screenshots/framed/{device}/{screen-name}.png`

**Approach priority:**
1. Playwright MCP (`mcp__plugin_playwright_playwright__*`) — render HTML template to screenshot
2. ImageMagick CLI — `composite` command for overlay
3. Manual fallback — provide raw screenshots and frame template files for user to compose

## Stage 3: Marketing Shots

1. Read brand book for: color palette, typography, tone of voice
2. For each framed screenshot:
   - Create a marketing composition:
     - Brand-colored gradient background
     - Framed device centered or offset
     - Text caption above or below (pulled from app description or brand book)
     - App name/logo if specified in brand book
   - Render using the same approach as Stage 2 (HTML template or ImageMagick)
3. Store in `screenshots/marketing/{device}/{screen-name}.png`

**Caption sources:**
- Brand book North Star statement
- Feature descriptions from epics
- Promotional text from `appstore/listing.json` if it exists

## Stage 4: Upload-Ready

1. Copy final marketing shots to upload structure
2. Validate each image:
   - Dimensions match Apple's requirements exactly
   - Format is PNG or JPEG
   - File size is under 500MB per image
3. Store in `screenshots/appstore/{device-class}/` ready for `asc` upload
4. Report summary: how many screenshots per device, any missing

## User Override

At any stage, the user can:
- Replace individual files in `screenshots/raw/`, `framed/`, or `marketing/`
- Re-run the skill — it checks for existing files and skips regeneration
- Run only specific stages by providing arguments: `/ios-screenshots raw` or `/ios-screenshots marketing`

## Storage Structure

```
screenshots/
├── raw/
│   ├── iphone-6.7/
│   ├── iphone-6.1/
│   ├── ipad-13/
│   ├── ipad-11/
│   ├── watch-ultra/
│   └── watch-series/
├── framed/
│   └── (same structure)
├── marketing/
│   └── (same structure)
└── appstore/
    └── (same structure, upload-ready)
```
