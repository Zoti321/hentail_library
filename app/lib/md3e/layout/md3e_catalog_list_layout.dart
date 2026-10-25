import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';

/// List column count for catalog browse (M3 lists on large window width).
///
/// Compact / medium: single column. Expanded and up: two columns (see M3 lists
/// guidelines for utilizing horizontal space on large screens).
int md3eComicListColumnCount(Md3eWindowSizeClass window) {
  switch (window) {
    case Md3eWindowSizeClass.compact:
    case Md3eWindowSizeClass.medium:
      return 1;
    case Md3eWindowSizeClass.expanded:
    case Md3eWindowSizeClass.large:
    case Md3eWindowSizeClass.extraLarge:
      return 2;
  }
}
