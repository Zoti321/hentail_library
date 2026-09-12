import 'package:flutter/material.dart';

/// Fixed GPU sampling for Read session page images.
///
/// **Page image fidelity** (see `CONTEXT.md`): render pages as close to the
/// source bitmap as layout allows — do not raise or lower [FilterQuality] for
/// scroll performance. [FilterQuality.medium] uses mipmaps and is Flutter's
/// recommended choice when downscaling; [FilterQuality.high] (bicubic, no
/// mipmaps) can introduce screentone moiré after settle and is forbidden here.
const FilterQuality kReaderPageFilterQuality = FilterQuality.medium;
