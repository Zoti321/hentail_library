import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/library_form.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('save waits for the shared simulated duration before completing', (
    WidgetTester tester,
  ) async {
    final List<LibraryForm> saved = <LibraryForm>[];
    await pumpMd3eApp(
      tester,
      home: Md3eLibraryEditPage(onSaved: saved.add),
    );

    await tester.tap(find.text('保存'));
    await tester.pump();

    // 等待状态：常量时长内尚未回调保存结果。
    final Duration total = Md3eMotion.labSimulatedSaveDuration;
    expect(total, const Duration(milliseconds: 280));
    await tester.pump(total - const Duration(milliseconds: 20));
    expect(saved, isEmpty, reason: '模拟保存期间不应完成');

    // 到达常量时长后完成保存。
    await tester.pump(const Duration(milliseconds: 40));
    expect(saved, hasLength(1));
  });
}
