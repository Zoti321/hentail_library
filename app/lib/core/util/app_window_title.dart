import 'package:flutter/foundation.dart';

/// OS / MaterialApp window title for the current App data profile affordance.
///
/// Non-Release builds (Debug / Profile → `dev` profile) append ` [dev]`.
/// See ADR-0010.
String appWindowTitle({bool isReleaseMode = kReleaseMode}) {
  const String base = 'hentai library';
  if (isReleaseMode) {
    return base;
  }
  return '$base [dev]';
}
