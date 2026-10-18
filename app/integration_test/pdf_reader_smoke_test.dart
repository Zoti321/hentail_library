import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/pdf_reader_smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('platform can open a PDF and read the first page as JPEG', (
    tester,
  ) async {
    await runPdfReaderPlatformSmoke();
  });
}
