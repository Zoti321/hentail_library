import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/widgets.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/scan_progress_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool deferredSectionsReady = false;

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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final HomePageLayoutTier layoutTier = homePageLayoutTierForWidth(
          viewportWidth,
        );
        final double horizontalPadding = homeContentHorizontalPadding(
          layoutTier,
        );
        final double maxWidth = (viewportWidth - horizontalPadding * 2).clamp(
          0,
          homeContentMaxWidth,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: tokens.layout.contentAreaPadding.vertical,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  HomePageHeader(
                    layoutTier: layoutTier,
                    title: '首页',
                    greetingText: greetingText,
                    onScan: onScan,
                  ),
                  SizedBox(height: tokens.spacing.xl + 12),
                  HomePageHeroSection(
                    layoutTier: layoutTier,
                    comicCount: comicCount,
                    isLibraryEmpty: isLibraryEmpty,
                    onScan: onScan,
                    enableHeavyStats: deferredSectionsReady,
                  ),
                  SizedBox(height: tokens.spacing.lg + 8),
                  HomePageContinueReadingSection(
                    layoutTier: layoutTier,
                    enabled: deferredSectionsReady,
                  ),
                  SizedBox(height: tokens.spacing.xl + 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
