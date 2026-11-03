import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/read_session/public.dart';
import 'package:hentai_library/shared/di/app_shell_providers.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/responsive_app_shell.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/app_router.dart';
import 'package:hentai_library/shared/di/read_session_launch_providers.dart';
import 'package:hentai_library/shared/di/comic_detail_providers.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> bootstrapShellSlotOverrides() => <Override>[
  appShellFeedbackBelowTitleBarFactoryProvider.overrideWithValue(
    () => <Widget>[
      const DiagnosticModeBanner(),
      ...libraryAdminShellFeedbackBelowTitleBar(),
    ],
  ),
  md3eAppShellNavigationSlotAssemblyProvider.overrideWithValue(
    buildLibraryAdminMd3eAppShellNavigationSlot,
  ),
];

List<Override> bootstrapCompositionOverrides() => <Override>[
  ...bootstrapShellSlotOverrides(),
  appRouterProvider.overrideWithValue(appRouter),
  readSessionLaunchPortProvider.overrideWith(createReadSessionLaunchPort),
  appShellOpenNavigationDrawerProvider.overrideWithValue(
    openAppShellNavigationDrawer,
  ),
  comicResolvedPageCountProvider.overrideWith((Ref ref, String comicId) async {
    final pages = await ref.read(comicImagesProvider(comicId: comicId).future);
    return pages.length;
  }),
];
