import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/lab/lab_library_catalog.dart';

import '../../../widgetbook/preview/md3e_home_page_preview_data.dart';

void main() {
  test('Home preview libraries share Lab catalog ids and display names', () {
    final List<String> catalogIds = LabLibraryCatalog.libraries()
        .map((row) => row.libraryId)
        .toList(growable: false);
    final List<String> homeIds = HomePagePreviewData.sampleLibraries()
        .map((row) => row.libraryId)
        .toList(growable: false);

    expect(homeIds, catalogIds);
    expect(
      HomePagePreviewData.sampleAggregateCounts().comicCount,
      LabLibraryCatalog.aggregateCounts().comicCount,
    );
  });
}
