import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';

/// iOS HIG minimum; used on compact (phone-width) layouts.
const double kCompactMinInteractiveSize = 44;

/// Icon-only tooltip wait — long enough to avoid hover noise, short enough to discover.
const Duration kIconTooltipWait = Duration(milliseconds: 600);

bool isCompactLayoutWidth(double width) =>
    AppLayoutBreakpoints.isCompact(width);

/// Visual control size stays [visualSize]; compact layouts expand the hit area.
double minInteractiveSize({required double visualSize, required bool compact}) {
  if (!compact) {
    return visualSize;
  }
  return visualSize < kCompactMinInteractiveSize
      ? kCompactMinInteractiveSize
      : visualSize;
}

Duration iconTooltipWait({required bool delayed}) {
  return delayed ? kIconTooltipWait : Duration.zero;
}
