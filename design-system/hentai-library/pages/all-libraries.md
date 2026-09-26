# Page Override: All Libraries

**Route:** `/libraries/all` · **Widget:** `AllLibrariesBrowsePage`  
**Overrides:** `MASTER.md`

---

## Purpose

Placeholder browse surface when no single library is selected. Prompts user to pick or create a library from sidebar.

## Layout

- Full shell child under `ResponsiveAppShell`
- Background: `cs.hentai.winBackground`
- Header row: optional compact `GhostButton.icon` (menu) + title `l10n.libraryTitle`
- Centered empty-state body with secondary hint text

## Components

- `GhostButton.icon` — `LucideIcons.menu`, 36px hit, `tokens.radius.md`
- Title: `tokens.text.titleLg`, `w600`, `cs.hentai.textPrimary`
- Hint: `tokens.text.bodySm`, `cs.hentai.textSecondary`

## Interactions

- Menu button → `appShellPageNavigationOpener(context)` only when non-null (compact)
- `allowPendingFadeThrough: true` on route — preserve transition when entering/leaving

## Anti-Patterns (This Page)

- ❌ Embedding full catalog grid here (belongs on `library` page)
- ❌ Hard-coded Chinese/English strings — use l10n

## Page Checklist

- [ ] Compact shows nav opener; medium+ relies on sidebar rail
- [ ] Empty state readable at 375px width
- [ ] No duplicate library management forms on this placeholder
