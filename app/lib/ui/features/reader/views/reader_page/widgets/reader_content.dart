import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/view/reader_viewport_host.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_image_filter_quality.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_scroll_activity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReaderContent extends HookConsumerWidget {
  const ReaderContent({
    super.key,
    required this.comicId,
    required this.incognito,
    this.startFromFirstPage = false,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.readingMode,
    this.onRequestNextPage,
  });

  final String comicId;
  final bool incognito;
  final bool startFromFirstPage;
  final int initialPage;
  final int? preferredPageIndex;
  final ReadingMode readingMode;
  final Future<void> Function()? onRequestNextPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<bool> isScrolling = useState(false);
    final ObjectRef<Timer?> settleTimer = useRef<Timer?>(null);

    useEffect(() {
      return () => settleTimer.value?.cancel();
    }, const <Object?>[]);

    void scheduleScrolling(bool next) {
      if (isScrolling.value == next) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isScrolling.value == next) {
          return;
        }
        isScrolling.value = next;
      });
    }

    bool onScrollNotification(ScrollNotification notification) {
      // PageView can emit metrics notifications during layout; never setState
      // synchronously from a notification handler.
      if (notification is ScrollUpdateNotification) {
        final double? delta = notification.scrollDelta;
        if (delta == null || delta == 0) {
          return false;
        }
        settleTimer.value?.cancel();
        settleTimer.value = null;
        scheduleScrolling(true);
        return false;
      }
      if (notification is ScrollEndNotification) {
        settleTimer.value?.cancel();
        settleTimer.value = Timer(kReaderFilterQualitySettleDelay, () {
          scheduleScrolling(false);
        });
      }
      return false;
    }

    // Mode switches swap viewports immediately — no AnimatedSwitcher overlap (P2-9).
    return NotificationListener<ScrollNotification>(
      onNotification: onScrollNotification,
      child: ReaderScrollActivity(
        isScrolling: isScrolling.value,
        child: ReaderViewportHost(
          key: ValueKey<ReadingMode>(readingMode),
          comicId: comicId,
          incognito: incognito,
          startFromFirstPage: startFromFirstPage,
          initialPage: initialPage,
          preferredPageIndex: preferredPageIndex,
          readingMode: readingMode,
          onRequestNextPage: onRequestNextPage,
        ),
      ),
    );
  }
}
