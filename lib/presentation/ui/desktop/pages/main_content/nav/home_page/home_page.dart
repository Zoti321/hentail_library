import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/home_page/widgets/widgets.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/scan_progress_dialog.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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
      barrierColor: Colors.transparent,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final int comicCount = ref.watch(
      libraryPageProvider.select((LibraryPageState state) {
        return state.rawList.length;
      }),
    );
    final String greetingText = '${greetingPhraseForNow()}，读者';
    void onScan() {
      onTapScanLibrary(context, ref);
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.clamp(0, homeContentMaxWidth);
        return SingleChildScrollView(
          padding: homePagePadding,
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
                      ref.read(libraryPageProvider.notifier).refreshStream();
                    },
                    onScan: onScan,
                  ),
                  SizedBox(height: tokens.spacing.xl + 12),
                  HomePageHeroSection(comicCount: comicCount, onScan: onScan),
                  SizedBox(height: tokens.spacing.lg + 8),
                  const HomePageContinueReadingSection(),
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
