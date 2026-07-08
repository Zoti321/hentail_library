import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';

enum LibraryLayoutTier { compact, medium, expanded }

LibraryLayoutTier libraryLayoutTierForWidth(double width) {
  if (AppLayoutBreakpoints.isCompact(width)) {
    return LibraryLayoutTier.compact;
  }
  if (AppLayoutBreakpoints.isMedium(width)) {
    return LibraryLayoutTier.medium;
  }
  return LibraryLayoutTier.expanded;
}

double libraryContentHorizontalPadding(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 16,
    LibraryLayoutTier.medium => 28,
    LibraryLayoutTier.expanded => 48,
  };
}

double libraryPageTitleFontSize(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 18,
    LibraryLayoutTier.medium => 22,
    LibraryLayoutTier.expanded => 26,
  };
}

double libraryToolbarActionSpacing(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 4,
    LibraryLayoutTier.medium => 6,
    LibraryLayoutTier.expanded => 8,
  };
}

bool libraryHeaderShowsCountChips(LibraryLayoutTier tier) {
  return tier != LibraryLayoutTier.compact;
}

double libraryGridMaxCrossAxisExtent(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 168,
    LibraryLayoutTier.medium => 188,
    LibraryLayoutTier.expanded => 200,
  };
}

double libraryGridSpacing(LibraryLayoutTier tier) {
  return switch (tier) {
    LibraryLayoutTier.compact => 12,
    LibraryLayoutTier.medium => 14,
    LibraryLayoutTier.expanded => 16,
  };
}
