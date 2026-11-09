import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/features/reader/presentation/navigation/apply_reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:hentai_library/shared/domain/models/models.dart'
    show AppSetting;
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/shared/ui/motion/app_motion.dart';
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
    final int readerAutoPlayIntervalSeconds = ref.watch(
      appSettingsStateProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.readerAutoPlayIntervalSeconds ?? 5,
      ),
    );
    final AutoPlayMode autoPlayMode = ref.watch(
      appSettingsStateProvider.select(
        (AsyncValue<AppSetting> value) =>
            value.asData?.value.autoPlayMode ?? kDefaultAutoPlayMode,
      ),
    );
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
        timer = Timer.periodic(interval, (_) {
          if (!context.mounted) {
            timer?.cancel();
            return;
          }
          if (ref.read(readerViewModelProvider(viewKey)).asData?.value ==
              null) {
            return;
          }
          unawaited(() async {
            final ({bool keepTicking, ReaderReplaceReaderRouteIntent? replace})
            tick = await viewModel.advanceAutoPlay(
              navContext: seriesNavContext,
              session: routeContext.session,
            );
            applyReaderNavigationIntent(context, tick.replace);
            if (!tick.keepTicking) {
              timer?.cancel();
            }
          }());
        });
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
}
