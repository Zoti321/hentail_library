import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('FabSizing.responsive', () {
    test('aligns with Kazumi default FAB (regular 56) on all breakpoints', () {
      for (final TargetPlatform platform in <TargetPlatform>[
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        for (final WindowSizeClass sizeClass in WindowSizeClass.values) {
          expect(
            FabSizing.responsive(sizeClass),
            M3EFabSize.regular,
            reason: '$platform / $sizeClass',
          );
        }
      }
    });
  });

  group('FabSizing.containerExtent', () {
    test('regular matches Material default FAB edge length', () {
      expect(FabSizing.containerExtent(M3EFabSize.regular), 56);
    });
  });
}
