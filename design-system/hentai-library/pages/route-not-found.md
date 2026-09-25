# Page Override: Route Not Found

**Route:** `/series` (invalid) · **Widget:** `RouteNotFoundPage`  
**Overrides:** `MASTER.md`

---

## Purpose

Friendly 404 when deep link or route has no handler. Centered empty state with navigation recovery.

## Layout

- Centered column, `mainAxisSize: min`
- Horizontal padding: `tokens.spacing.xl`
- Vertical gap: `tokens.spacing.lg` (Column `spacing`)
- No shell header dependency — content self-contained

## Components

- Icon: `LucideIcons.circleAlert`, 48px, `cs.hentai.textTertiary`
- Title: `tokens.text.titleSm`, `w600`, `textPrimary`
- Hint: `tokens.text.bodySm`, `textSecondary`, center aligned
- Actions: two `GhostButton.iconText`
  - Home → `context.go('/home')`
  - Library → `LibraryManagementActions.goCurrentLibraryBrowseFromContext`

## Interactions

- Fade-through page transition (`buildDesktopFadeThroughPage`)
- Buttons are secondary ghost style — no primary filled CTA needed

## Anti-Patterns (This Page)

- ❌ Raw Material `Icons.error_outline`
- ❌ Dead-end with no navigation actions
- ❌ English-only hard-coded copy

## Page Checklist

- [ ] Both recovery buttons work from cold deep link
- [ ] Readable on compact width (375px)
- [ ] Icon is decorative if buttons have text labels (Semantics on buttons)
