import 'package:hentai_library/core/util/platform_desktop.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';

/// List column count for catalog browse, from window size class and platform.
///
/// Compact (phone portrait) is always one column. Desktop packs more columns
/// because the window is wide and rows are short; mobile tablets stay sparser.
///
/// | size class | desktop | mobile |
/// | ---------- | ------- | ------ |
/// | compact    | 1       | 1      |
/// | medium     | 2       | 2      |
/// | expanded   | 3       | 2      |
/// | large      | 4       | 3      |
/// | extraLarge | 4       | 3      |
///
/// [desktop] defaults to the running platform ([isDesktop]).
int comicListColumnCount(WindowSizeClass window, {bool? desktop}) {
  final bool isDesktopLayout = desktop ?? isDesktop;
  switch (window) {
    case WindowSizeClass.compact:
      return 1;
    case WindowSizeClass.medium:
      return 2;
    case WindowSizeClass.expanded:
      return isDesktopLayout ? 3 : 2;
    case WindowSizeClass.large:
      return isDesktopLayout ? 4 : 3;
    case WindowSizeClass.extraLarge:
      return isDesktopLayout ? 4 : 3;
  }
}
