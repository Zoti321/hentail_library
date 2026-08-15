import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/domain/reading/reader_session_snapshot.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

const String _comicId = 'reader-controller-comic';
const ReaderControllerKey _key = (
  comicId: _comicId,
  incognito: false,
  startFromFirstPage: false,
);
const ReaderControllerKey _incognitoKey = (
  comicId: _comicId,
  incognito: true,
  startFromFirstPage: false,
);

Comic _comic({int pageCount = 10}) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: _comicId,
    path: '/tmp/$_comicId.cbz',
    resourceType: ResourceType.cbz,
    resourceSize: 1,
    createdAt: now,
    lastUpdatedAt: now,
    title: 'Controller Test',
    pageCount: pageCount,
  );
}

ReaderSessionSnapshot _snapshot({int pageCount = 10, int resumePage = 1}) {
  final Comic comic = _comic(pageCount: pageCount);
  return ReaderSessionSnapshot(
    comic: comic,
    pages: List<ReadSessionPage>.generate(
      pageCount,
      (int index) =>
          ReadSessionArchivePage(comicId: _comicId, pageIndex: index),
    ),
    resumePageIndex: resumePage,
  );
}

class _MemoryAppSettingRepository implements AppSettingRepository {
  _MemoryAppSettingRepository(this._setting);

  AppSetting _setting;

  @override
  Future<AppSetting> load() async => _setting;

  @override
  Future<void> save(AppSetting setting) async {
    _setting = setting;
  }

  @override
  Future<bool?> peekLegacyAutoScan() async => null;
}

ProviderContainer _createContainer({
  required AppSetting initialSetting,
  ReaderControllerKey key = _key,
  ReaderSessionSnapshot? snapshot,
}) {
  final ReaderSessionSnapshot session = snapshot ?? _snapshot();
  return ProviderContainer(
    overrides: <Override>[
      appSettingRepoProvider.overrideWithValue(
        _MemoryAppSettingRepository(initialSetting),
      ),
      readerSessionOpenProvider(
        comicId: key.comicId,
        incognito: key.incognito,
      ).overrideWith((Ref ref) async => session),
    ],
  );
}

ReaderController _controller(
  ProviderContainer container,
  ReaderControllerKey key,
) => container.read(readerControllerProvider(key).notifier);

ReaderState? _state(ProviderContainer container, ReaderControllerKey key) =>
    container.read(readerControllerProvider(key)).asData?.value;

void main() {
  group('auto-play session state', () {
    test('opens with autoPlayEnabled false', () async {
      final ProviderContainer container = _createContainer(
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
      );
      addTearDown(container.dispose);

      final ReaderState state = await container.read(
        readerControllerProvider(_key).future,
      );

      expect(state.autoPlayEnabled, isFalse);
    });

    test(
      'setAutoPlayEnabled(true) keeps auto-play on for same comic',
      () async {
        final ProviderContainer container = _createContainer(
          initialSetting: AppSetting(readingMode: ReadingMode.paged),
        );
        addTearDown(container.dispose);

        await container.read(readerControllerProvider(_key).future);
        _controller(container, _key).setAutoPlayEnabled(true);

        expect(_state(container, _key)?.autoPlayEnabled, isTrue);
      },
    );

    test('new comic session starts with auto-play off', () async {
      const ReaderControllerKey otherKey = (
        comicId: 'reader-controller-other',
        incognito: false,
        startFromFirstPage: false,
      );
      final ReaderSessionSnapshot otherSnapshot = ReaderSessionSnapshot(
        comic: Comic(
          comicId: otherKey.comicId,
          path: '/tmp/${otherKey.comicId}.cbz',
          resourceType: ResourceType.cbz,
          resourceSize: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          lastUpdatedAt: DateTime.utc(2026, 1, 1),
          title: 'Other Comic',
          pageCount: 5,
        ),
        pages: List<ReadSessionPage>.generate(
          5,
          (int index) => ReadSessionArchivePage(
            comicId: otherKey.comicId,
            pageIndex: index,
          ),
        ),
        resumePageIndex: 1,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          appSettingRepoProvider.overrideWithValue(
            _MemoryAppSettingRepository(
              AppSetting(readingMode: ReadingMode.paged),
            ),
          ),
          readerSessionOpenProvider(
            comicId: _key.comicId,
            incognito: _key.incognito,
          ).overrideWith((Ref ref) async => _snapshot()),
          readerSessionOpenProvider(
            comicId: otherKey.comicId,
            incognito: otherKey.incognito,
          ).overrideWith((Ref ref) async => otherSnapshot),
        ],
      );
      addTearDown(container.dispose);

      await container.read(readerControllerProvider(_key).future);
      _controller(container, _key).setAutoPlayEnabled(true);

      final ReaderState otherState = await container.read(
        readerControllerProvider(otherKey).future,
      );

      expect(_state(container, _key)?.autoPlayEnabled, isTrue);
      expect(otherState.autoPlayEnabled, isFalse);
    });

    test('setReadingMode(webtoon) turns auto-play off', () async {
      final ProviderContainer container = _createContainer(
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
      );
      addTearDown(container.dispose);

      await container.read(readerControllerProvider(_key).future);
      final ReaderController controller = _controller(container, _key);
      controller.setAutoPlayEnabled(true);
      controller.setReadingMode(ReadingMode.webtoon);

      expect(_state(container, _key)?.autoPlayEnabled, isFalse);
      expect(_state(container, _key)?.readingMode, ReadingMode.webtoon);
    });
  });

  group('reading mode from AppSetting', () {
    test(
      'opens with readingMode from AppSetting (not default paged)',
      () async {
        final ProviderContainer container = _createContainer(
          initialSetting: AppSetting(readingMode: ReadingMode.webtoon),
        );
        addTearDown(container.dispose);

        final ReaderState state = await container.read(
          readerControllerProvider(_key).future,
        );

        expect(state.readingMode, ReadingMode.webtoon);
      },
    );

    test('syncs readingMode when AppSetting changes', () async {
      final ProviderContainer container = _createContainer(
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
      );
      addTearDown(container.dispose);

      await container.read(readerControllerProvider(_key).future);
      await container
          .read(settingsProvider.notifier)
          .setReadingMode(ReadingMode.webtoon);

      expect(_state(container, _key)?.readingMode, ReadingMode.webtoon);
    });
  });

  group('page navigation', () {
    test('paged to webtoon keeps currentIndex', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 20, resumePage: 7),
      );
      addTearDown(container.dispose);

      await container.read(readerControllerProvider(_incognitoKey).future);
      _controller(container, _incognitoKey).setReadingMode(ReadingMode.webtoon);

      final ReaderState? state = _state(container, _incognitoKey);
      expect(state?.readingMode, ReadingMode.webtoon);
      expect(state?.currentIndex, 7);
    });

    test('dualPage to webtoon remaps to last page in spread', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.dualPage),
        snapshot: _snapshot(pageCount: 10, resumePage: 3),
      );
      addTearDown(container.dispose);

      await container.read(readerControllerProvider(_incognitoKey).future);
      _controller(container, _incognitoKey).setReadingMode(ReadingMode.webtoon);

      expect(_state(container, _incognitoKey)?.currentIndex, 4);
    });

    test('nextPage and prevPage move within bounds', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 5, resumePage: 1),
      );
      addTearDown(container.dispose);

      await container.read(readerControllerProvider(_incognitoKey).future);
      final ReaderController controller = _controller(container, _incognitoKey);

      controller.prevPage();
      expect(_state(container, _incognitoKey)?.currentIndex, 1);

      controller.nextPage();
      expect(_state(container, _incognitoKey)?.currentIndex, 2);

      controller.setIndex(5);
      controller.nextPage();
      expect(_state(container, _incognitoKey)?.currentIndex, 5);
    });

    test('setIndex ignores out-of-range and accepts valid page', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 5, resumePage: 2),
      );
      addTearDown(container.dispose);

      await container.read(readerControllerProvider(_incognitoKey).future);
      final ReaderController controller = _controller(container, _incognitoKey);

      controller.setIndex(0);
      expect(_state(container, _incognitoKey)?.currentIndex, 2);

      controller.setIndex(6);
      expect(_state(container, _incognitoKey)?.currentIndex, 2);

      controller.setIndex(4);
      expect(_state(container, _incognitoKey)?.currentIndex, 4);
    });
  });
}
