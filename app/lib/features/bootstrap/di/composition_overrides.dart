import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/app_shell_slot_overrides.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/responsive_app_shell.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/app_router.dart';
import 'package:hentai_library/features/reader/public.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/reader_launch_providers.dart';
import 'package:hentai_library/shared/di/comic_detail_providers.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/shared/di/app_shell_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:riverpod/misc.dart' show Override;

List<Override> bootstrapCompositionOverrides() => <Override>[
  ...bootstrapShellSlotOverrides(),
  appRouterProvider.overrideWithValue(appRouter),
  readerLaunchPortProvider.overrideWith(createReaderLaunchPort),
  appShellOpenNavigationDrawerProvider.overrideWithValue(
    openAppShellNavigationDrawer,
  ),
  // DB page_count only — do not open a Read session from the detail page.
  comicResolvedPageCountProvider.overrideWith((Ref ref, String comicId) async {
    final Comic? comic = await ref
        .read(comicLookupRepositoryProvider)
        .findById(comicId);
    return comic?.pageCount ?? 0;
  }),
];
