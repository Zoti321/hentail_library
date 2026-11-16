import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/composition/overrides/app_shell_slot_overrides.dart';
import 'package:hentai_library/shared/presentation/providers/app_shell_providers.dart';
import 'package:riverpod/misc.dart' show Override, ProviderException;

void main() {
  test('未注入时 Shell 槽位 Provider 抛出 UnimplementedError', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(appShellFeedbackBelowTitleBarFactoryProvider),
      throwsA(isA<ProviderException>()),
    );
    expect(
      () => container.read(appShellNavigationSlotAssemblyProvider),
      throwsA(isA<ProviderException>()),
    );
  });

  test('bootstrapShellSlotOverrides 注入后可产出反馈 widget 与导航组装函数', () {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[...bootstrapShellSlotOverrides()],
    );
    addTearDown(container.dispose);

    final List<Widget> feedback = container.read(
      appShellFeedbackBelowTitleBarFactoryProvider,
    )();
    expect(feedback, isNotEmpty);

    final AppShellNavigationSlotAssembly assembly = container.read(
      appShellNavigationSlotAssemblyProvider,
    );
    expect(assembly, isNotNull);
  });
}
