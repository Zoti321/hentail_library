import 'package:flutter/material.dart';

/// GPU sampling for catalog / browse / detail-thumb surfaces (Tier C).
///
/// Matches Comic library browse cards ([AppComicImage] default):
/// [FilterQuality.medium], without display-width [cacheWidth] downsampling.
/// Read sessions stay on **Page image fidelity** (Tier R /
/// [kReaderPageFilterQuality]).
const FilterQuality kCatalogImageFilterQuality = FilterQuality.medium;
