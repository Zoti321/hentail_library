# ADR-0065: Page image max-edge decode safety

## Status

Accepted; supersedes ADR-0060 Decision bullet “decode without … decode-size caps” (viewport caps remain forbidden; oversized max-edge cap is allowed)

## Context

ADR-0060 required Read session page images (Comic and Image set) to decode without viewport `cacheWidth` (or equivalent decode-size caps) and to sample at `FilterQuality.high`, accepting oversized-bitmap memory risk until #591. Product now needs a safety valve that prevents hard failures on huge source pages without softening ordinary pages or restoring everyday viewport downdecode.

## Decision

1. Keep ADR-0060’s bans: no viewport-anchored page-image `cacheWidth` for ordinary pages; `FilterQuality.high` fixed; no scroll/idle quality switching; no sharpen/beautify; no user-facing quality preference in this decision.
2. When a source page’s longest edge exceeds **8192** px, decode a proportionally scaled bitmap whose longest edge equals **8192**. Below or equal to that edge, decode at source resolution.
3. Apply the same max-edge policy on Read session display and prefetch/precache paths via one Flutter decode-size policy. Do not rescale bitmaps in Rust prefetch.
4. Do not change named/`reader` ImageCache entry or byte budgets in this decision.
5. If capped decode still fails, use existing page error/retry behavior; do not auto-fall back to viewport `cacheWidth`; do not abort the whole Read session.
6. No user-visible “downscaled” chrome in this decision; diagnostic logging is allowed.
7. Record the exception under GLOSSARY **Page image fidelity**; do not invent a separate glossary head term for the valve.

## Consequences

### Positive

- Oversized pages can open without allocating full multi-gigapixel bitmaps.
- Ordinary pages keep source-resolution fidelity; agents cannot treat the valve as a general soft-decode license.
- One Flutter seam owns the rule for render and precache.

### Negative

- Pages above the cap are shown softer than the true source when viewed zoomed.
- Header probe + capped decode adds a small cost on the page image path.
- Device-class multi-tier budgets and secondary viewport fallback remain deferred.

## References

- #591
- ADR-0060
- GLOSSARY **Page image fidelity**
