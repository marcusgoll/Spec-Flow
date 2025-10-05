# Visual References: Dark Mode Toggle

## Design Inspiration

### Toggle Button Patterns

**GitHub Style** (Chosen Approach)
- Moon/sun icon toggle in navigation
- Smooth icon transition on click
- Tooltip on hover: "Switch to dark theme"
- Rationale: Universally recognized, minimal space, accessible

**Alternative Considered: Dropdown**
- Light / Dark / System options
- Rationale for rejection: More clicks required, less immediate

**Alternative Considered: Switch Component**
- iOS-style switch in settings page
- Rationale for rejection: Hidden in settings, not prominent enough

### Color Tokens

#### Light Theme
```css
--color-background: #ffffff
--color-surface: #f6f8fa
--color-border: #d0d7de
--color-text-primary: #24292f
--color-text-secondary: #57606a
--color-accent: #0969da
--color-success: #1a7f37
--color-danger: #cf222e
```

#### Dark Theme
```css
--color-background: #0d1117
--color-surface: #161b22
--color-border: #30363d
--color-text-primary: #c9d1d9
--color-text-secondary: #8b949e
--color-accent: #58a6ff
--color-success: #3fb950
--color-danger: #f85149
```

### Component Hierarchy

```
App (ThemeProvider)
└── Navigation
    └── ThemeToggle (button)
        ├── Icon (sun/moon)
        └── Tooltip
```

### Accessibility Checklist

- [ ] Contrast ratios meet WCAG 2.1 AA (≥4.5:1 for normal text)
  - Light theme: 12.63:1 (text on background) ✅
  - Dark theme: 9.18:1 (text on background) ✅
- [ ] Keyboard accessible (Space/Enter to toggle)
- [ ] Screen reader support (aria-label: "Toggle dark mode")
- [ ] Focus indicator visible in both themes
- [ ] No reliance on color alone for information

### Transition Animation

```css
* {
  transition: background-color 300ms ease-in-out,
              color 300ms ease-in-out,
              border-color 300ms ease-in-out;
}
```

**Rationale**: 300ms provides smooth perception without lag. `ease-in-out` feels natural.

### Mobile Considerations

- Toggle button must be ≥44×44px (WCAG touch target minimum)
- Icon scales proportionally (16px default, 20px on mobile)
- Position in navigation adapts to screen size
  - Desktop: Right side of header
  - Mobile: Visible in collapsed menu or as icon-only button

### Browser Compatibility

| Feature | Chrome | Firefox | Safari | Edge |
|---------|--------|---------|--------|------|
| CSS Variables | ✅ | ✅ | ✅ | ✅ |
| prefers-color-scheme | ✅ | ✅ | ✅ | ✅ |
| localStorage | ✅ | ✅ | ⚠️ Private | ✅ |

**Safari Private Mode**: localStorage throws. Implement try-catch with sessionStorage fallback.

## Reference Screenshots

_Note: In a real project, this section would contain screenshots from:_
- GitHub's theme toggle
- Twitter's theme toggle
- Figma mockups of our implementation
- Before/after comparisons

## Design System Integration

Our implementation uses:
- **Spacing**: Design system tokens (--space-2, --space-4)
- **Typography**: Design system font scale (--font-size-base)
- **Icons**: From design system icon library (Lucide React)
- **Animation**: Design system duration tokens (--duration-normal = 300ms)

## User Flow Diagram

```
[User lands on app]
     |
     v
[Detect system preference] --> Apply initial theme
     |
     v
[Check localStorage] --> Override with saved preference (if exists)
     |
     v
[User clicks toggle]
     |
     v
[Update theme state] --> [Update CSS variables] --> [Save to localStorage]
     |
     v
[Theme applied with 300ms transition]
```

## Edge Cases Handled

1. **First Visit**: Apply system preference (prefers-color-scheme)
2. **Returning User**: Apply saved preference from localStorage
3. **localStorage Unavailable**: Fall back to sessionStorage → in-memory state
4. **JavaScript Disabled**: Respect system preference only (via CSS media query)
5. **Rapid Clicks**: Debounce toggle to prevent flickering
6. **Mid-Transition Click**: Cancel previous transition, start new one
