# ADR-0063: MD3 standard scheme variant and contrast

## Status

Accepted; partially supersedes ADR-0037 Decision §2 (variant / contrast)

## Context

ADR-0037 locked production Tone-based assembly to `DynamicSchemeVariant.fidelity` with implicit contrast `0.0`, so fixed palette seeds stayed close to the chosen hue. Product now wants both the dynamic-scheme **variant** and **contrast** on Material's standard baselines: `tonalSpot` and `ContrastLevel.standard` (`0.0`).

## Decision

1. Production `ColorScheme.fromSeed` uses `dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot` and `contrastLevel: ContrastLevel.standard` (explicit).
2. Dynamic-color and fixed-palette paths keep the same assembly entry; only seed selection differs (unchanged from ADR-0037 §5).
3. Do not enable `expressive` or non-standard contrast tiers (`medium` / `high`) in this decision.

## Consequences

### Positive

- Matches Material defaults for scheme construction; less surprise vs framework / design-tool previews that assume tonalSpot.
- Contrast tier is explicit in code and tests.

### Negative

- Primary / surface roles may look more pastel than under fidelity for the same seed; palette presets need visual re-check.
- Fixed-scheme “所选即所得” is weaker than under fidelity (ADR-0037 goal trade-off).

## References

- ADR-0037
- material_ui `ColorScheme.fromSeed` / `ContrastLevel` / `DynamicSchemeVariant`
