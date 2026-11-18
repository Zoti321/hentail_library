import 'package:hentai_library/features/reader/domain/read_session_source.dart';

/// Exit navigation after closing a Read session.
enum ReadSessionExitPolicy {
  /// Comic go_router path back to Comic detail.
  goToComicDetail,

  /// Image set MaterialPageRoute stack pop.
  popRoute,
}

/// Domain flags for shared Reader shell vs Comic-only features (ADR-0061).
///
/// Derived from [ReadSessionSource] (and incognito). Application/presentation
/// consume these flags instead of branching on catalog kind.
final class ReadSessionCapabilities {
  const ReadSessionCapabilities({
    required this.persistProgress,
    required this.seriesNavigation,
    required this.imageSetNavigation,
    required this.coverActions,
    required this.nativeSession,
    required this.nativePrefetch,
    required this.seriesAutoPlayModes,
    required this.exitPolicy,
  });

  /// Writing Reading history / reading_stats (Comic, non-incognito).
  final bool persistProgress;

  /// Series volume navigation, catalog sheet, boundary prompts.
  final bool seriesNavigation;

  /// Previous/next and open-by-id across non-empty Image sets of the same
  /// library; each jump opens a new Read session source.
  final bool imageSetNavigation;

  /// Set Comic/Series cover actions in the more menu.
  final bool coverActions;

  /// Native Comic archive/dir session via [NativeReaderPort].
  final bool nativeSession;

  /// Native archive prefetch (Flutter warm window may still run).
  final bool nativePrefetch;

  /// Series once/loop auto-play modes in session settings.
  final bool seriesAutoPlayModes;

  final ReadSessionExitPolicy exitPolicy;

  static ReadSessionCapabilities from(
    ReadSessionSource source, {
    bool incognito = false,
  }) {
    return switch (source) {
      ComicReadSessionSource() => ReadSessionCapabilities(
        persistProgress: !incognito,
        seriesNavigation: true,
        imageSetNavigation: false,
        coverActions: true,
        nativeSession: true,
        nativePrefetch: true,
        seriesAutoPlayModes: true,
        exitPolicy: ReadSessionExitPolicy.goToComicDetail,
      ),
      ImageSetReadSessionSource() => const ReadSessionCapabilities(
        persistProgress: false,
        seriesNavigation: false,
        imageSetNavigation: true,
        coverActions: false,
        nativeSession: false,
        nativePrefetch: false,
        seriesAutoPlayModes: false,
        exitPolicy: ReadSessionExitPolicy.popRoute,
      ),
    };
  }
}
