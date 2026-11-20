import 'package:flutter/material.dart';

/// Fixed GPU sampling for Read session page images.
///
/// **Page image fidelity** (see `GLOSSARY.md`, ADR-0060/0065): decode at
/// source resolution with max-edge oversized safety applied once in the
/// reader page ImageProvider load path, and sample at [FilterQuality.high].
/// Do not raise or lower [FilterQuality] for scroll performance, and do not
/// apply sharpen/beautify.
const FilterQuality kReaderPageFilterQuality = FilterQuality.high;
