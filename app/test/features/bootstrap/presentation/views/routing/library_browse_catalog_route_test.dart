import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/features/bootstrap/presentation/views/routing/app_router.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_browse_preferences_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_browse_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_library_page.dart';
import 'package:hentai_library/features/library_admin/public/contracts.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';

import '../../../../../support/pump_localized_app.dart';

class _MemoryPrefs implements ImageSetBrowsePreferencesRepository {
  @override
  Future<ImageSetBrowsePreferences> load() async =>
      ImageSetBrowsePreferences.defaults;

  @override
  Future<void> reset() async {}

  @override
  Future<void> save(ImageSetBrowsePreferences preferences) async {}
}

const LocalLibrary _imageSetLibrary = (
  libraryId: 'img-1',
  kind: 'local',
  catalogKind: 'image_set',
  rootPath: r'D:\images',
  name: 'Gallery',
  enabledResourceFormatCategories: [],
  username: '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: false,
  sidebarOrder: 0,
);

void main() {
  testWidgets(
    'image set library opens the image set browse page instead of comic browse',
    (WidgetTester tester) async {
      final List<Override> overrides = <Override>[
        librariesStateProvider.overrideWithValue(
          const AsyncData<LibrariesState>(
            LibrariesState(libraries: <LocalLibrary>[_imageSetLibrary]),
          ),
        ),
        libraryRevisionStateProvider.overrideWithValue(
          const LibraryRevisionState(),
        ),
        librarySyncStateProvider.overrideWithValue((
          running: false,
          cancelled: false,
          targetLibraryId: null,
          error: null,
          progress: null,
        )),
        imageSetListQueryProvider.overrideWithValue(
          (String libraryId) async => const <ImageSet>[],
        ),
        imageSetBrowsePreferencesRepositoryProvider.overrideWithValue(
          _MemoryPrefs(),
        ),
        imageSetCatalogPageQueryProvider.overrideWithValue(
          ({
            required String libraryId,
            required PageRequest request,
            required ImageSetBrowsePreferences preferences,
          }) async =>
              const PagedImageSetCatalog(
            items: <ImageSetCatalogItem>[],
            totalCount: 0,
            page: 1,
            pageSize: 20,
          ),
        ),
      ];
      Widget app(Widget home) => ProviderScope(
        overrides: overrides,
        child: buildLocalizedTestMaterialApp(home: home),
      );

      await tester.pumpWidget(app(const LibraryBrowsePage(libraryId: 'img-1')));
      await tester.pumpAndSettle();

      expect(find.byType(ImageSetLibraryPage), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('暂无图集。同步后将显示库中发现的图集。'), findsOneWidget);

      await tester.pumpWidget(app(const SizedBox()));
      await tester.pump();
    },
  );
}
