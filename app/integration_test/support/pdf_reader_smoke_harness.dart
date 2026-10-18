import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/reader.dart';
import 'package:hentai_library/src/rust/frb_generated.dart';
import 'package:path_provider/path_provider.dart';

/// 各平台 Watch 冒烟共用的最小单页 PDF（无版权素材）。
const String kMinimalOnePagePdf = '''
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

String pdfSmokeComicId() => 'pdf-${Platform.operatingSystem}-smoke';

/// 宿主 + pdfium + Reader FRB 最小契约：init → open → list → 首页 JPEG → close。
Future<void> runPdfReaderPlatformSmoke() async {
  await RustLib.init();

  final comicId = pdfSmokeComicId();
  final dir = await getTemporaryDirectory();
  final pdfPath = '${dir.path}/comic.pdf';
  await File(pdfPath).writeAsString(kMinimalOnePagePdf, flush: true);

  try {
    await openReaderFrb(comicId: comicId, path: pdfPath, resourceType: 'pdf');
  } on HentaiErrorDto catch (e) {
    fail('openReaderFrb failed: ${e.code} | ${e.message} | ${e.context}');
  }

  final list = await loadPageListFrb(
    comicId: comicId,
    path: pdfPath,
    resourceType: 'pdf',
  );
  expect(list.pageCount, 1);

  final page0 = loadPageBytesFrb(
    comicId: comicId,
    path: pdfPath,
    resourceType: 'pdf',
    pageIndex: 0,
  );
  expect(page0.length, greaterThanOrEqualTo(3));
  expect(page0[0], 0xFF);
  expect(page0[1], 0xD8);
  expect(page0[2], 0xFF);

  closeReaderFrb(comicId: comicId);
}
