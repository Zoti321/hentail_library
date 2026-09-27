import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/domain/repositories/home_page_repository.dart';
import 'package:hentai_library/src/rust/api/home.dart' as rust;
import 'package:hentai_library/src/rust/api/probe.dart' as rust_probe;

class HomePageRepositoryImpl implements HomePageRepository {
  const HomePageRepositoryImpl();

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return guardFrbStream(
      () => rust
          .watchHomePageCountsFrb(excludeR18: excludeR18)
          .map(_mapCounts),
      fallbackMessage: '读取首页统计失败',
    );
  }

  @override
  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5({
    required bool excludeR18,
  }) {
    return guardFrbStream(
      () => rust
          .watchContinueReadingTop5Frb(excludeR18: excludeR18)
          .map(
            (List<rust.HomeContinueReadingDto> rows) =>
                rows.map(_mapContinueReading).toList(),
          ),
      fallbackMessage: '读取继续阅读失败',
    );
  }

  @override
  Stream<List<HomeLibraryAlert>> watchHomeLibraryAlerts() {
    return guardFrbStream(
      () => rust.watchHomeLibraryAlertsFrb().map(
        (List<rust.HomeLibraryAlertDto> rows) =>
            rows.map(_mapAlert).toList(growable: false),
      ),
      fallbackMessage: '读取首页库提醒失败',
    );
  }

  @override
  Stream<List<HomeRecentlyAddedEntry>> watchRecentlyAddedOnHome({
    required bool excludeR18,
  }) {
    return guardFrbStream(
      () => rust
          .watchRecentlyAddedOnHomeFrb(excludeR18: excludeR18)
          .map(
            (List<rust.HomeRecentlyAddedDto> rows) =>
                rows.map(_mapRecentlyAdded).toList(growable: false),
          ),
      fallbackMessage: '读取最近入库失败',
    );
  }

  @override
  Future<LibraryProbeResult> probeLibrary({
    required String libraryId,
    String? password,
  }) {
    return guardFrb(
      () async => _mapProbeResult(
        await rust_probe.probeLibraryFrb(
          libraryId: libraryId,
          password: password,
        ),
      ),
      fallbackMessage: '探测库资源失败',
    );
  }

  HomePageCounts _mapCounts(rust.HomePageCountsDto dto) {
    return HomePageCounts(
      comicCount: dto.comicCount,
      tagCount: dto.tagCount,
      seriesCount: dto.seriesCount,
      authorCount: dto.authorCount,
      libraryCount: dto.libraryCount,
    );
  }

  HomeContinueReadingEntry _mapContinueReading(
    rust.HomeContinueReadingDto dto,
  ) {
    return HomeContinueReadingEntry(
      comicId: dto.comicId,
      title: dto.title,
      lastReadTime: DateTime.fromMillisecondsSinceEpoch(
        dto.lastReadTimeMs.toInt(),
      ),
      pageIndex: dto.pageIndex,
    );
  }

  HomeLibraryAlert _mapAlert(rust.HomeLibraryAlertDto dto) {
    return HomeLibraryAlert(
      libraryId: dto.libraryId,
      displayName: dto.displayName,
      kind: _mapAlertKind(dto.kind),
      lastSuccessAt: dto.lastSuccessAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dto.lastSuccessAtMs!.toInt()),
      lastErrorMessage: dto.lastErrorMessage,
      staleDays: dto.staleDays,
      pendingResourceCount: dto.pendingResourceCount,
    );
  }

  HomeLibraryAlertKind _mapAlertKind(rust.HomeLibraryAlertKindDto kind) {
    return switch (kind) {
      rust.HomeLibraryAlertKindDto.remoteUnreachable =>
        HomeLibraryAlertKind.remoteUnreachable,
      rust.HomeLibraryAlertKindDto.syncFailed =>
        HomeLibraryAlertKind.syncFailed,
      rust.HomeLibraryAlertKindDto.staleSync => HomeLibraryAlertKind.staleSync,
      rust.HomeLibraryAlertKindDto.pendingResourcesDetected =>
        HomeLibraryAlertKind.pendingResourcesDetected,
    };
  }

  HomeRecentlyAddedEntry _mapRecentlyAdded(rust.HomeRecentlyAddedDto dto) {
    return HomeRecentlyAddedEntry(
      comicId: dto.comicId,
      title: dto.title,
      libraryId: dto.libraryId,
      libraryDisplayName: dto.libraryDisplayName,
      createdAt: DateTime.fromMillisecondsSinceEpoch(dto.createdAtMs.toInt()),
    );
  }

  LibraryProbeResult _mapProbeResult(rust_probe.LibraryProbeResultDto dto) {
    return LibraryProbeResult(
      libraryId: dto.libraryId,
      addedCount: dto.addedCount,
      changedCount: dto.changedCount,
      removedCount: dto.removedCount,
      unreachable: dto.unreachable,
      errorMessage: dto.errorMessage,
      probedAt: DateTime.fromMillisecondsSinceEpoch(dto.probedAtMs.toInt()),
      baselineMissing: dto.baselineMissing,
    );
  }
}
