import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/database/dao/home_page_dao_types.dart';
import 'package:hentai_library/services/comic/content_rating/auto_detect_comic_content_rating_service.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/home_page/widgets/widgets.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/scan_progress_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool deferredSectionsReady = false;
  bool isAutoDetectingContentRating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => deferredSectionsReady = true);
    });
  }

  void onTapScanLibrary(BuildContext context, WidgetRef ref) {
    final bool running = ref.read(
      scanLibraryControllerProvider.select((ScanLibraryState state) {
        return state.running;
      }),
    );
    if (!running) {
      ref.read(scanLibraryControllerProvider.notifier).start();
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ScanProgressDialog(),
    );
  }

  Future<void> onTapAutoDetectContentRating() async {
    if (isAutoDetectingContentRating) {
      return;
    }
    setState(() {
      isAutoDetectingContentRating = true;
    });
    try {
      final AutoDetectComicContentRatingService service = ref.read(
        autoDetectComicContentRatingServiceProvider,
      );
      final AutoDetectComicContentRatingResult result = await service
          .executeAutoDetect();
      if (!mounted) {
        return;
      }
      if (result.matchedComics == 0) {
        showInfoToast(context, '未命中分级关键词目录');
        return;
      }
      showSuccessToast(
        context,
        '已识别 ${result.matchedComics} 本疑似成人漫画，成功更新 ${result.updatedComics} 本为 R18。',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(context, error);
    } finally {
      if (mounted) {
        setState(() {
          isAutoDetectingContentRating = false;
        });
      }
    }
  }

  String greetingPhraseForNow() {
    final int hour = DateTime.now().hour;
    if (hour < 5) {
      return '凌晨好';
    }
    if (hour < 9) {
      return '早上好';
    }
    if (hour < 12) {
      return '上午好';
    }
    if (hour < 14) {
      return '中午好';
    }
    if (hour < 18) {
      return '下午好';
    }
    if (hour < 23) {
      return '晚上好';
    }
    return '夜深了';
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<HomePageCounts> homePageCounts = ref.watch(
      homePageCountsStreamProvider,
    );
    final int comicCount = homePageCounts.maybeWhen(
      data: (HomePageCounts c) => c.comicCount,
      orElse: () => 0,
    );
    final bool isLibraryEmpty = homePageCounts.maybeWhen(
      data: (HomePageCounts c) => c.comicCount == 0,
      orElse: () => false,
    );
    final String greetingText = '${greetingPhraseForNow()}，读者';
    void onScan() {
      onTapScanLibrary(context, ref);
    }

    void onAutoDetectContentRating() {
      onTapAutoDetectContentRating();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.clamp(
          0,
          homeContentMaxWidth,
        );
        return SingleChildScrollView(
          padding: tokens.layout.contentAreaPadding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  HomePageHeader(
                    title: '首页',
                    greetingText: greetingText,
                    onRefresh: () {
                      ref.invalidate(homePageCountsStreamProvider);
                      ref.invalidate(homeContinueReadingTop5StreamProvider);
                      ref.invalidate(homeSeriesComicOrderMapStreamProvider);
                    },
                    onAutoDetectContentRating: onAutoDetectContentRating,
                    onScan: onScan,
                  ),
                  SizedBox(height: tokens.spacing.xl + 12),
                  HomePageHeroSection(
                    comicCount: comicCount,
                    isLibraryEmpty: isLibraryEmpty,
                    onScan: onScan,
                    enableHeavyStats: deferredSectionsReady,
                  ),
                  SizedBox(height: tokens.spacing.lg + 8),
                  HomePageContinueReadingSection(
                    enabled: deferredSectionsReady,
                  ),
                  SizedBox(height: tokens.spacing.xl + 8),
                  HomePageShortcutEntries(onScan: onScan),
                  SizedBox(height: tokens.spacing.xl * 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
