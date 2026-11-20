# ADR-0060: Page image fidelity at source resolution

## Status

Accepted; decode-size-cap bullet partially superseded by ADR-0065 (max-edge oversized safety; viewport caps remain forbidden)

## Context

GLOSSARY **Page image fidelity** previously locked Read session GPU sampling at `FilterQuality.medium` and allowed viewport `cacheWidth` downdecode. Product now requires Comic and Image set Read sessions to preserve source pixel resolution and use higher-quality sampling, accepting memory pressure risk until a separate oversized-image safety policy (#591) lands.

## Decision

- Decode Read session page images without viewport `cacheWidth` (or equivalent decode-size caps) on the page render and prefetch paths.
- Keep page-image GPU sampling fixed at `FilterQuality.high`; do not change quality for scroll/idle, and do not sharpen/beautify.
- Catalog covers and detail thumbnails keep their own `FilterQuality.high` + display-sized `cacheWidth` policy; they are not governed by this ADR’s decode rule.
- Document the accepted oversized-bitmap risk in GLOSSARY and track a safety valve in #591; do not ship a user-facing quality preference in this decision.

## Consequences

### Positive

- Read sessions match source bitmap fidelity more closely for both Comic and Image set sessions.
- GLOSSARY and Reader constants stay aligned with product intent.

### Negative

- Large page bitmaps can increase memory use; oversized max-edge safety is ADR-0065 / #591.
- Screened artwork may show more moiré at rest than under the prior medium+mipmap policy.
