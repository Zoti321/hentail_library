import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_controller.dart';
import 'package:hentai_library/features/read_session/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:hentai_library/shared/domain/models/models.dart'
    show AppSetting;
import 'package:hentai_library/shared/domain/reading/auto_play_mode.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
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

  final ReaderControllerKey viewKey;
  final ReaderRouteContext routeContext;
  final ReaderNavContextData? seriesNavContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderController controller = ref.read(
      readerControllerProvider(viewKey).notifier,
    );
    final bool readerAutoPlayEnabled = ref.watch(
      readerControllerProvider(viewKey).select(
        (AsyncValue<ReaderState> asyncState) =>
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
      readerControllerProvider(viewKey)
          .select((AsyncValue<ReaderState> asyncState) {
            final ReaderState? readerState = asyncState.asData?.value;
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
          if (ref.read(readerControllerProvider(viewKey)).asData?.value ==
              null) {
            return;
          }
          final GoRouter router = GoRouter.of(context);
          unawaited(() async {
            final bool keepTicking = await controller.advanceAutoPlay(
              navContext: seriesNavContext,
              session: routeContext.session,
              router: router,
            );
            if (!keepTicking) {
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
        controller,
        ref,
        reduceMotion,
      ],
    );
    return const SizedBox.shrink();
  }
}
