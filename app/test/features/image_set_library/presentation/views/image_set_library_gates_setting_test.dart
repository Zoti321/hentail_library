import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_library_gates_setting.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

class _GatesProbe {
  bool? lastMutation;
  bool? lastManaged;

  Future<void> setMutation(String libraryId, {required bool enabled}) async {
    lastMutation = enabled;
  }

  Future<void> setManaged(String libraryId, {required bool enabled}) async {
    lastManaged = enabled;
  }
}

void main() {
  testWidgets('toggles resource mutation and managed layout via commands', (
    WidgetTester tester,
  ) async {
    final _GatesProbe probe = _GatesProbe();
    await pumpLocalizedApp(
      tester,
      overrides: <Override>[
        imageSetLibraryGatesQueryProvider.overrideWithValue(
          (_) async => const ImageSetLibraryGates(
            resourceMutation: false,
            managedLayout: false,
          ),
        ),
        imageSetSetResourceMutationCommandProvider.overrideWithValue(
          probe.setMutation,
        ),
        imageSetSetManagedLayoutCommandProvider.overrideWithValue(
          probe.setManaged,
        ),
      ],
      home: const Scaffold(
        body: ImageSetLibraryGatesSetting(libraryId: 'lib-img'),
      ),
    );
    await tester.pumpAndSettle();

    final Finder switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    await tester.tap(switches.at(0));
    await tester.pumpAndSettle();
    expect(probe.lastMutation, isTrue);

    await tester.tap(switches.at(1));
    await tester.pumpAndSettle();
    expect(probe.lastManaged, isTrue);
  });
}