import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/features/reader/presentation/navigation/apply_reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';
import 'package:hentai_library/features/reader/public/reading_preferences_providers.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Isolates autoplay timer subscriptions so index ticks don't rebuild the page shell.
class ReaderAutoPlayBinder extends HookConsumerWidget {
  const ReaderAutoPlayBinder({
    super.key,
    required this.viewKey,
    required this.routeContext,
    required this.seriesNavContext,
  });

  final ReaderViewModelKey viewKey;
  final ReaderRouteContext routeContext;
  final ReaderNavContextData? seriesNavContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderViewModel viewModel = ref.read(
      readerViewModelProvider(viewKey).notifier,
    );
    final bool readerAutoPlayEnabled = ref.watch(
      readerViewModelProvider(viewKey).select(
        (AsyncValue<ReaderUiState> asyncState) =>
            asyncState.asData?.value.autoPlayEnabled ?? false,
      ),
    );
    final ({int intervalSeconds, AutoPlayMode mode}) autoPlayPreferences = ref
        .watch(
          readingPreferencesProvider.select(
            (ReadingPreferences prefs) => (
              intervalSeconds: prefs.autoPlayIntervalSeconds,
              mode: prefs.autoPlayMode,
            ),
          ),
        );
    final int readerAutoPlayIntervalSeconds =
        autoPlayPreferences.intervalSeconds;
    final AutoPlayMode autoPlayMode = autoPlayPreferences.mode;
    final ({int currentIndex, int totalPages, ReadingMode readingMode})?
    autoPlayState = ref.watch(
      readerViewModelProvider(viewKey)
          .select((AsyncValue<ReaderUiState> asyncState) {
            final ReaderUiState? readerState = asyncState.asData?.value;
            if (readerState == null) {
              return null;
            }
            return (
              currentIndex: readerState.currentIndex,
              totalPages: readerState.totalPages,
              readingMode: readerState.readingMode,
            );
          }),
    );
    final bool reduceMotion = reduceMotionOf(context);
    final String? nextComicId = seriesNavContext?.nextItem?.comicId;
    final List<ReaderComicListItem>? seriesItems = seriesNavContext?.items;
    final String? firstComicId = seriesItems != null && seriesItems.isNotEmpty
        ? seriesItems.first.comicId
        : null;

    useEffect(
      () {
        final bool canStartAutoPlay =
            readerAutoPlayAllowed(
              userEnabled: readerAutoPlayEnabled,
              reduceMotion: reduceMotion,
            ) &&
            autoPlayState != null &&
            autoPlayState.readingMode.supportsAutoPlay &&
            autoPlayState.totalPages > 0;
        if (!canStartAutoPlay) {
          return null;
        }
        final Duration interval = Duration(
          seconds: readerAutoPlayIntervalSeconds,
        );
        Timer? timer;
        void onTick() => _handleTick(
          context: context,
          ref: ref,
          viewKey: viewKey,
          viewModel: viewModel,
          seriesNavContext: seriesNavContext,
          cancelTimer: () => timer?.cancel(),
        );
        timer = Timer.periodic(interval, (_) => onTick());
        return () {
          timer?.cancel();
        };
      },
      <Object?>[
        readerAutoPlayEnabled,
        readerAutoPlayIntervalSeconds,
        autoPlayMode,
        autoPlayState?.currentIndex,
        autoPlayState?.totalPages,
        autoPlayState?.readingMode,
        nextComicId,
        firstComicId,
        routeContext.comicId,
        viewModel,
        ref,
        reduceMotion,
      ],
    );
    return const SizedBox.shrink();
  }

  void _handleTick({
    required BuildContext context,
    required WidgetRef ref,
    required ReaderViewModelKey viewKey,
    required ReaderViewModel viewModel,
    required ReaderNavContextData? seriesNavContext,
    required VoidCallback cancelTimer,
  }) {
    if (!context.mounted) {
      cancelTimer();
      return;
    }
    if (ref.read(readerViewModelProvider(viewKey)).asData?.value == null) {
      return;
    }
    unawaited(() async {
      final ({bool keepTicking, ReaderReplaceReaderRouteIntent? replace}) tick =
          await viewModel.advanceAutoPlay(
            navContext: seriesNavContext,
            session: routeContext.session,
          );
      applyReaderNavigationIntent(context, tick.replace);
      if (!tick.keepTicking) {
        cancelTimer();
      }
    }());
  }
}
