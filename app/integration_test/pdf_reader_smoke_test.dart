import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/reader.dart';
import 'package:hentai_library/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android can open a PDF and read the first page as JPEG', (
    tester,
  ) async {
    await RustLib.init();

    final dir = await getTemporaryDirectory();
    final pdfPath = '${dir.path}/comic.pdf';
    await File(pdfPath).writeAsString(_minimalOnePagePdf, flush: true);

    try {
      await openReaderFrb(
        comicId: 'pdf-android-smoke',
        path: pdfPath,
        resourceType: 'pdf',
      );
    } on HentaiErrorDto catch (e) {
      fail('openReaderFrb failed: ${e.code} | ${e.message} | ${e.context}');
    }
    final list = await loadPageListFrb(
      comicId: 'pdf-android-smoke',
      path: pdfPath,
      resourceType: 'pdf',
    );
    expect(list.pageCount, 1);

    final page0 = loadPageBytesFrb(
      comicId: 'pdf-android-smoke',
      path: pdfPath,
      resourceType: 'pdf',
      pageIndex: 0,
    );
    expect(page0.length, greaterThanOrEqualTo(3));
    expect(page0[0], 0xFF);
    expect(page0[1], 0xD8);
    expect(page0[2], 0xFF);

    closeReaderFrb(comicId: 'pdf-android-smoke');
  });
}

const _minimalOnePagePdf = '''
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>
endobj
xref
0 4
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
trailer
<< /Size 4 /Root 1 0 R >>
startxref
190
%%EOF
''';
