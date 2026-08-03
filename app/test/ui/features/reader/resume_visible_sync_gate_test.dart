import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/resume_visible_sync_gate.dart';

void main() {
  group('ResumeVisibleSyncGate', () {
    test('ignores visible rewrites until resume target is observed', () {
      final ResumeVisibleSyncGate gate = ResumeVisibleSyncGate();
      gate.beginProgrammaticAlign(targetOneBased: 54);

      expect(gate.onVisibleIndex(38), isNull);
      expect(gate.isSuppressed, isTrue);

      // SPL often reports ±1 around the jump target while settling.
      expect(gate.onVisibleIndex(53), isNull);
      expect(gate.isSuppressed, isFalse);

      expect(gate.onVisibleIndex(55), 55);
    });

    test('legacy one-frame unsuppress would allow downward rewrite', () {
      // Characterization of the pre-fix race: clearing suppress before the
      // resume target is visible lets a lower index win and later persist.
      final ResumeVisibleSyncGate gate = ResumeVisibleSyncGate();
      gate.beginProgrammaticAlign(targetOneBased: 54);
      gate.debugForceUnsuppress();
      expect(gate.onVisibleIndex(38), 38);
    });

    test('timeout unsuppress still refuses first mismatch then accepts', () {
      final ResumeVisibleSyncGate gate = ResumeVisibleSyncGate(
        alignTimeout: const Duration(milliseconds: 50),
      );
      gate.beginProgrammaticAlign(
        targetOneBased: 54,
        now: DateTime.utc(2026, 1, 1),
      );
      expect(
        gate.onVisibleIndex(38, now: DateTime.utc(2026, 1, 1, 0, 0, 0, 60)),
        38,
      );
    });
  });
}
