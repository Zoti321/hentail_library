import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_adaptive_panel.dart';

void main() {
  test('compact and medium use bottom sheet, expanded+ uses side sheet', () {
    expect(
      Md3eReaderAdaptivePanel.preferBottomSheet(Md3eBreakpoints.medium - 1),
      isTrue,
    );
    expect(
      Md3eReaderAdaptivePanel.preferBottomSheet(Md3eBreakpoints.expanded - 1),
      isTrue,
    );
    expect(
      Md3eReaderAdaptivePanel.preferBottomSheet(Md3eBreakpoints.expanded),
      isFalse,
    );
  });
}
