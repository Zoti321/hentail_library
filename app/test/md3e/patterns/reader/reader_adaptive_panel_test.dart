import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_adaptive_panel.dart';

void main() {
  test('compact and medium use bottom sheet, expanded+ uses side sheet', () {
    expect(
      ReaderAdaptivePanel.preferBottomSheet(Breakpoints.medium - 1),
      isTrue,
    );
    expect(
      ReaderAdaptivePanel.preferBottomSheet(Breakpoints.expanded - 1),
      isTrue,
    );
    expect(
      ReaderAdaptivePanel.preferBottomSheet(Breakpoints.expanded),
      isFalse,
    );
  });
}
