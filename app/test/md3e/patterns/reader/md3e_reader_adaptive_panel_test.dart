import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_adaptive_panel.dart';

void main() {
  test('compact and medium use bottom sheet, expanded+ uses side sheet', () {
    expect(
      Md3eReaderAdaptivePanel.preferBottomSheet(
        Md3eBreakpoints.medium - 1,
      ),
      isTrue,
    );
    expect(
      Md3eReaderAdaptivePanel.preferBottomSheet(
        Md3eBreakpoints.expanded - 1,
      ),
      isTrue,
    );
    expect(
      Md3eReaderAdaptivePanel.preferBottomSheet(Md3eBreakpoints.expanded),
      isFalse,
    );
  });
}
