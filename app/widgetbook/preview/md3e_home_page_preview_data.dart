import 'package:hentai_library/shared/ui/lab/lab_library_catalog.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

/// Widgetbook / Lab 首页预览数据（非生产 FRB）。
abstract final class Md3eHomePagePreviewData {
  static List<Md3eHomeLibraryDashboardRow> sampleLibraries({
    DateTime? referenceNow,
  }) => libraries(referenceNow: referenceNow);

  static List<Md3eHomeLibraryDashboardRow> libraries({
    DateTime? referenceNow,
  }) => Md3eLabLibraryCatalog.libraries(referenceNow: referenceNow);

  static Md3eHomeAggregateCounts sampleAggregateCounts() =>
      Md3eLabLibraryCatalog.aggregateCounts();
}
