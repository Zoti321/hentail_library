import 'package:hentai_library/composition/modules/library_admin/app_shell_slot.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/shared/presentation/providers/app_shell_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// ADR-0027：Shell 反馈条与 MD3E 导航槽（bootstrap 注入 shared/presentation/providers token）。
List<Override> bootstrapShellSlotOverrides() => <Override>[
  appShellFeedbackBelowTitleBarFactoryProvider.overrideWithValue(
    () => <Widget>[
      const DiagnosticModeBanner(),
      ...libraryAdminShellFeedbackBelowTitleBar(),
    ],
  ),
  appShellNavigationSlotAssemblyProvider.overrideWithValue(
    buildLibraryAdminAppShellNavigationSlot,
  ),
];
