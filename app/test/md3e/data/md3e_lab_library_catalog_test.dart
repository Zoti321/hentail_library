import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/data/md3e_lab_library_catalog.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_page_preview_data.dart';

void main() {
  test('Home preview libraries share Lab catalog ids and display names', () {
    final List<String> catalogIds = Md3eLabLibraryCatalog.libraries()
        .map((row) => row.libraryId)
        .toList(growable: false);
    final List<String> homeIds = Md3eHomePagePreviewData.sampleLibraries()
        .map((row) => row.libraryId)
        .toList(growable: false);

    expect(homeIds, catalogIds);
    expect(
      Md3eHomePagePreviewData.sampleAggregateCounts().comicCount,
      Md3eLabLibraryCatalog.aggregateCounts().comicCount,
    );
  });
}
