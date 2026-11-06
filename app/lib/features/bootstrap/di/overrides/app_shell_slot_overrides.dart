import 'package:flutter/material.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/di/app_shell_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// ADR-0027：Shell 反馈条与 MD3E 导航槽（bootstrap 注入 shared/di token）。
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
