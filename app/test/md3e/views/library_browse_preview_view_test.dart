import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/views/library_browse_preview_view.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('library browse preview shows title and sample items', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: const Md3eLibraryBrowsePreviewView(itemCount: 2),
    );
    expect(find.text('书库预览'), findsOneWidget);
    expect(find.text('示例本子 1'), findsOneWidget);
  });
}
