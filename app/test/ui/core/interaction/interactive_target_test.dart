import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/interaction/interactive_target.dart';

void main() {
  group('minInteractiveSize', () {
    test('keeps desktop visual size', () {
      expect(minInteractiveSize(visualSize: 32, compact: false), 32);
    });

    test('expands compact icon buttons to 44', () {
      expect(minInteractiveSize(visualSize: 32, compact: true), 44);
    });

    test('does not shrink already large compact targets', () {
      expect(minInteractiveSize(visualSize: 48, compact: true), 48);
    });
  });

  group('iconTooltipWait', () {
    test('uses 600ms for delayed icon tooltips', () {
      expect(iconTooltipWait(delayed: true), kIconTooltipWait);
    });

    test('uses zero wait when delay is off', () {
      expect(iconTooltipWait(delayed: false), Duration.zero);
    });
  });
}
