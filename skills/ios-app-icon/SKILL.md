---
name: ios-app-icon
description: Create a layered Liquid Glass app icon using Apple's IconComposer. Generates layer assets, composes via computer-use MCP, adds to Xcode project. Falls back to manual instructions if automation is flaky.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# App Icon Creation

Create a layered Liquid Glass app icon for iOS 26+.

## Process

### 1. Analyze Brand Identity

Read `docs/product-vision/00-product-bounds.md` for:
- Color palette
- Icon style preferences
- Tone of voice (playful, professional, minimal, etc.)

### 2. Generate Layer Assets

Create icon layers at 1024x1024 base resolution:

- **Foreground** — the primary symbol or graphic (e.g., app logo, key visual)
- **Background** — solid color, gradient, or pattern from brand palette
- **Tint** (optional) — color overlay for Liquid Glass effect

Generate as PNGs. If the user has provided their own layers in `assets/icon/layers/`, skip generation and use those instead.

Store in:
```
assets/
└── icon/
    ├── layers/
    │   ├── foreground.png    (1024x1024, transparent background)
    │   ├── background.png    (1024x1024)
    │   └── tint.png          (optional, 1024x1024)
    ├── composed/
    │   └── AppIcon.icon      (IconComposer output)
    └── legacy/
        └── AppIcon-1024.png  (flat fallback)
```

### 3. Compose with IconComposer (Automated)

Attempt automated composition using computer-use MCP:

1. Request access to IconComposer via `mcp__computer-use__request_access`
2. Open IconComposer: `mcp__computer-use__open_application` with "Icon Composer"
3. Take screenshot to verify it opened
4. Import foreground layer:
   - Click "Front" layer slot
   - Use file dialog to select `assets/icon/layers/foreground.png`
5. Import background layer:
   - Click "Back" layer slot
   - Use file dialog to select `assets/icon/layers/background.png`
6. Configure Liquid Glass properties:
   - Enable glass effect if appropriate for the icon style
   - Adjust fill opacity based on brand identity
7. Preview across appearances (light/dark)
8. Export: File > Save As > save to `assets/icon/composed/AppIcon.icon`

### 4. Fallback: Manual Instructions

If computer-use automation fails at any step:

1. Report which step failed
2. Provide clear manual instructions:
   ```
   The layer assets are ready at:
   - Foreground: assets/icon/layers/foreground.png
   - Background: assets/icon/layers/background.png

   To compose in IconComposer:
   1. Open IconComposer (Applications or via Xcode > Open Developer Tool)
   2. Drag foreground.png onto the "Front" layer
   3. Drag background.png onto the "Back" layer
   4. Adjust Liquid Glass properties to taste
   5. Preview in light and dark mode
   6. File > Save As > save to your project's assets/icon/composed/AppIcon.icon
   ```
3. Wait for user to confirm the .icon file is saved

### 5. Add to Xcode Project

1. Copy `assets/icon/composed/AppIcon.icon` to the app's asset catalog
2. Update `project.yml` if needed to reference the new icon
3. Run `xcodegen generate`
4. Build to verify the icon appears correctly

### 6. Generate Legacy Fallback

For older OS targets that don't support .icon format:
1. Create a flat 1024x1024 PNG from the composed icon layers
2. Store at `assets/icon/legacy/AppIcon-1024.png`
3. Add to asset catalog as fallback AppIcon

### User Override

- Provide your own layer PNGs in `assets/icon/layers/` — skip generation
- Provide your own .icon file in `assets/icon/composed/` — skip IconComposer
- Provide a flat PNG in `assets/icon/legacy/` — skip legacy generation
