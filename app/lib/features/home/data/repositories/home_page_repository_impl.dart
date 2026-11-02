import 'package:hentai_library/shared/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/src/rust/api/home.dart' as rust;
import 'package:hentai_library/src/rust/api/probe.dart' as rust_probe;

class HomePageRepositoryImpl implements HomePageRepository {
  const HomePageRepositoryImpl();

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return guardFrbStream(
      () => rust.watchHomePageCountsFrb(excludeR18: excludeR18).map(_mapCounts),
      fallbackMessage: '读取首页统计失败',
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
  Stream<List<HomeLibraryStat>> watchLibraryStats({required bool excludeR18}) {
    return guardFrbStream(
      () => rust
          .watchLibraryHomeStatsFrb(excludeR18: excludeR18)
          .map(
            (List<rust.LibraryHomeStatDto> rows) =>
                rows.map(_mapLibraryStat).toList(growable: false),
          ),
      fallbackMessage: '读取库统计失败',
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

  HomeLibraryStat _mapLibraryStat(rust.LibraryHomeStatDto dto) {
    return HomeLibraryStat(
      libraryId: dto.libraryId,
      comicCount: dto.comicCount,
      seriesCount: dto.seriesCount,
      lastSuccessfulSyncAt: dto.lastSuccessfulSyncAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              dto.lastSuccessfulSyncAtMs!.toInt(),
            ),
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
