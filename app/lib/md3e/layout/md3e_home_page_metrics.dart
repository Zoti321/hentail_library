import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_spacing.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';

/// [Md3eHomePage] 间距与内容宽度（对齐生产 Home 与 M3 边距）。
abstract final class Md3eHomePageMetrics {
  static double contentHorizontalPadding(Md3eWindowSizeClass sizeClass) {
    return Md3eLibraryPageHeaderMetrics.contentHorizontalPadding(sizeClass);
  }

  static double contentMaxWidth(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => double.infinity,
      Md3eWindowSizeClass.medium => 960,
      _ => 1120,
    };
  }

  static double sectionVerticalSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space16,
      _ => Md3eSpacing.space24,
    };
  }

  static double greetingToSectionSpacing(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => Md3eSpacing.space20,
      _ => Md3eSpacing.space28,
    };
  }
}
