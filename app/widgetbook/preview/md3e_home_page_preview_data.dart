import 'package:hentai_library/shared/ui/lab/lab_library_catalog.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_aggregate_counts.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

/// Widgetbook / Lab 首页预览数据（非生产 FRB）。
abstract final class HomePagePreviewData {
  static List<HomeLibraryDashboardRow> sampleLibraries({
    DateTime? referenceNow,
  }) => libraries(referenceNow: referenceNow);

  static List<HomeLibraryDashboardRow> libraries({DateTime? referenceNow}) =>
      LabLibraryCatalog.libraries(referenceNow: referenceNow);

  static HomeAggregateCounts sampleAggregateCounts() =>
      LabLibraryCatalog.aggregateCounts();
}
