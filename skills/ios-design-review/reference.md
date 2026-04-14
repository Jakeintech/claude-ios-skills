# iOS Design Review Reference

## Liquid Glass API Quick Reference

### Core Modifier
```swift
.glassEffect() // Default: .regular variant, .capsule shape
.glassEffect(_ glass: Glass, in shape: some Shape, isEnabled: Bool)
```

### Glass Variants
| Variant | Use For | Never Use For |
|---------|---------|---------------|
| `.regular` | Toolbars, buttons, nav bars, standard controls | Content layer |
| `.clear` | Small floating controls over media (requires bold foreground) | Standard UI |
| `.identity` | Conditional toggling (no layout recalculation) | Permanent elements |

### Key Rules
- Glass is ONLY for the navigation layer that floats above app content
- Never apply glass to content (lists, tables, cards, media)
- Never stack glass on glass
- `.tint()` conveys semantic meaning only, never decoration
- `.interactive()` enables scaling/bouncing/shimmering (iOS only)
- Always use `GlassEffectContainer` for multiple glass elements
- `.buttonStyle(.glass)` for secondary actions, `.glassProminent` for primary

### Morphing
```swift
.glassEffectID(_ id: ID, in namespace: Namespace.ID)
.glassEffectUnion(id: ID, namespace: Namespace.ID)
```
Use `.bouncy` animation for morphing transitions.

## Apple HIG Checklist

### Navigation
- [ ] Standard navigation patterns (NavigationStack, TabView)
- [ ] Back button present and functional
- [ ] No custom chrome replacing system navigation
- [ ] Tab bar uses SF Symbols, not text-only tabs

### Typography
- [ ] System fonts preferred (SF Pro, SF Rounded, New York)
- [ ] Dynamic Type support on all text
- [ ] No text smaller than 11pt
- [ ] Proper font weight hierarchy (title > headline > body > caption)

### Layout
- [ ] Respects safe areas (no content behind notch/home indicator)
- [ ] Standard margins (16pt horizontal padding)
- [ ] Consistent spacing using Apple's 8pt grid
- [ ] Proper keyboard avoidance

### Touch Targets
- [ ] All interactive elements minimum 44x44pt
- [ ] Adequate spacing between tappable elements
- [ ] No small text-only buttons

### Color & Contrast
- [ ] Minimum 4.5:1 contrast ratio for text
- [ ] Minimum 3:1 for large text and UI components
- [ ] Proper use of semantic colors (.primary, .secondary, .accent)
- [ ] Works in both light and dark mode
- [ ] Respects Increased Contrast accessibility setting

### SF Symbols
- [ ] Using SF Symbols, not emojis or custom icons where symbols exist
- [ ] Correct symbol rendering mode for context
- [ ] Consistent weight/scale across the screen
- [ ] Symbols have accessibility labels

### Accessibility
- [ ] VoiceOver labels on all interactive elements
- [ ] VoiceOver reading order makes logical sense
- [ ] Accessibility traits set correctly (.button, .header, .link)
- [ ] Reduced Motion respected (no gratuitous animation)
- [ ] Reduced Transparency respected (glass degrades gracefully)

### iOS 26 Specific
- [ ] Liquid Glass on navigation layer only
- [ ] No glass-on-glass stacking
- [ ] GlassEffectContainer for grouped glass elements
- [ ] Glass adapts to Reduce Transparency setting
- [ ] Tint used for meaning, not decoration
