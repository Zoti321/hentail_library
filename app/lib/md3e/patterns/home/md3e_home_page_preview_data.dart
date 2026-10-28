import 'package:hentai_library/md3e/data/md3e_lab_library_catalog.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_aggregate_counts.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';

/// Widgetbook / Lab 首页预览数据（非生产 FRB）。
abstract final class Md3eHomePagePreviewData {
  static List<Md3eHomeLibraryDashboardRow> sampleLibraries({
    DateTime? referenceNow,
  }) =>
      libraries(referenceNow: referenceNow);

  static List<Md3eHomeLibraryDashboardRow> libraries({
    DateTime? referenceNow,
  }) =>
      Md3eLabLibraryCatalog.libraries(referenceNow: referenceNow);

  static Md3eHomeAggregateCounts sampleAggregateCounts() =>
      Md3eLabLibraryCatalog.aggregateCounts();
}
