# Page Override: Author Detail

**Surface:** modal via `showAdaptiveFormSurfaceWidget` · **Widget:** `AuthorDetailSurface`  
**Overrides:** `MASTER.md`

Not a routed page. Opened from metadata author chips, catalog author chips, and related author entry points.

---

## Purpose

Author identity card: banner + avatar, rename in place, external profile links, facet chips, top comic covers. Close returns to the caller; search / comic open pop the dialog then push a route.

## Layout

- `AdaptiveFormSurface`: title `authorDetailTitle`, **max width 560**, radius `tokens.radius.xs`, `fitContentHeight: false`
- Compact: full-page under title bar (same adaptive shell as metadata editors)
- Body column: header stack, then comics section (`tokens.spacing.lg` gap)
- Header: 140px banner, 88px avatar with 4px surface ring overlapping banner midline
- Name + links sit to the right of the avatar; min height keeps the ring from colliding with the comics section

## Components

- `_AuthorNameRow` — title `titleLg` / w700; pencil → inline `TextField` (Enter / blur submit, Esc cancel)
- **Verified mark:** `LucideIcons.badgeCheck` at 20px, color **`colorScheme.primary`** — same token as metadata `OutlinedMetaChip(verified: true)` on `/metadata?tab=` authors. Do not use `cs.hentai.success`.
- `_AuthorLinksWrap` — wrap of borderless link actions + outlined “添加链接” chip
- Facet chips stay **outlined** `OutlinedMetaChip` (parody / character / tag + count)
- Cover cards 96×144, 2:3, tooltip title

## Author links (this surface only)

Borderless `OutlinedMetaChip(showBorder: false)` — icon + label only, **no chip stroke / fill at rest**.

| Token | Use |
|-------|-----|
| `cs.primary` | Platform icon + label (Fluent-style link on `cs.surface`) |
| `cs.surfaceContainer` | Hover / press wash (existing chip interactive overlay) |
| `tokens.spacing.md` | Horizontal gap between links (room for reserved remove slot) |
| `tokens.spacing.sm` | Wrap run gap |

**Hover layout (do not regress):**

- Desktop: remove control (`LucideIcons.x`, tooltip `authorDetailDeleteLink`) is **always laid out** (`Visibility` + `maintainSize`) and only **revealed** on hover.
- Cause of the height jump: inserting a 16px control (and Material `IconButton` min size) on hover grew the chip, reflowed the wrap, and resized the dialog.
- Do **not** use Material `IconButton` here — keep a 16×16 hit box so chip height stays equal to the label row.
- Tooltip on the whole link shows URL; truncation stays one line (`maxLines: 1`). Full URL is also the operable tooltip, not hover-only recovery for a wrapped label.

Add-link remains outlined compact chip (`plus` + copy). Invalid URL → toast; successful add collapses the field.

## Interactions

- Link tap: `url_launcher` external; failure toast `authorDetailOpenLinkFailed`
- Desktop hover-only remove; compact / touch always shows remove (slot still reserved)
- Delete is immediate (no confirm dialog) — hover reveal is the safeguard on desktop
- “在搜索中查看”: exact author query; collaborator facet chips AND current author
- Cover tap: pop dialog, push `/comic/:id`

## Anti-Patterns (This Surface)

- ❌ Verified icon in success green (admin list uses primary)
- ❌ Outlined / filled chips for external links
- ❌ Inserting or removing the delete control from the tree on hover
- ❌ `AnimatedContainer` from `Colors.transparent` (black α=0) to hover fill — lerp flashes dark gray; rest fill must be the hover color at alpha 0
- ❌ `IconButton` default 48px min size on compact chips
- ❌ Hover-only tooltip as the only way to read a truncated URL without a reserved one-line label
- ❌ Landing-page / WebGL / parallax treatments (ignore generic `--design-system` marketing extras)

## Page Checklist

- [ ] Verified icon color matches metadata author chips (`cs.primary`)
- [ ] Hovering a link does not change dialog height or chip size
- [ ] Links wrap with `spacing.md`; labels do not wrap inside a chip
- [ ] Rename / add-link inline editors still submit on Enter and cancel on Esc
- [ ] Compact uses the same adaptive form surface, not a second Material page
