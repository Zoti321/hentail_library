import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/domain/home_page_repository.dart';
import 'package:hentai_library/src/rust/api/home.dart' as rust;

class HomePageRepositoryImpl implements HomePageRepository {
  const HomePageRepositoryImpl();

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
    );
  }

  HomeLibraryAlertKind _mapAlertKind(rust.HomeLibraryAlertKindDto kind) {
    return switch (kind) {
      rust.HomeLibraryAlertKindDto.remoteUnreachable =>
        HomeLibraryAlertKind.remoteUnreachable,
      rust.HomeLibraryAlertKindDto.syncFailed =>
        HomeLibraryAlertKind.syncFailed,
      rust.HomeLibraryAlertKindDto.staleSync => HomeLibraryAlertKind.staleSync,
    };
  }
}
