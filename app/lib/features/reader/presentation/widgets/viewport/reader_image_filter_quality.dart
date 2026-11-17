import 'package:flutter/material.dart';

/// Fixed GPU sampling for Read session page images.
///
/// **Page image fidelity** (see `GLOSSARY.md`, ADR-0060): decode at source
/// resolution and sample at [FilterQuality.high]. Do not raise or lower
/// [FilterQuality] for scroll performance, and do not apply sharpen/beautify.
/// Oversized-bitmap safety is tracked separately (#591); not enforced here.
const FilterQuality kReaderPageFilterQuality = FilterQuality.high;
