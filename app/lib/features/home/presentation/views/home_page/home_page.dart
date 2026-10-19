import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/page_content_width_layout.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/features/home/presentation/views/home_page/widgets/widgets.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_probe_coordinator_notifier.dart';
import 'package:hentai_library/features/home/presentation/view_models/home_page_dashboard_notifier.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;
  bool deferredSectionsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(homePageVisibleProvider.notifier).setVisible(true);
      setState(() => deferredSectionsReady = true);
    });
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void activate() {
    super.activate();
    _setHomeVisibleAfterFrame(true);
  }

  @override
  void deactivate() {
    _setHomeVisibleAfterFrame(false);
    super.deactivate();
  }

  /// Riverpod 禁止在 widget 树构建期间修改 provider，故推迟到帧结束。
  void _setHomeVisibleAfterFrame(bool visible) {
    final HomePageVisibleNotifier notifier = ref.read(
      homePageVisibleProvider.notifier,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (visible && !mounted) {
        return;
      }
      notifier.setVisible(visible);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final ({int comicCount, int libraryCount, bool showEmptyOnboarding})
    homeCountsLeaf = ref.watch(
      homePageCountsStreamProvider.select((AsyncValue<HomePageCounts> async) {
        return async.maybeWhen(
          data: (HomePageCounts c) => (
            comicCount: c.comicCount,
            libraryCount: c.libraryCount,
            showEmptyOnboarding: c.libraryCount == 0 || c.comicCount == 0,
          ),
          orElse: () =>
              (comicCount: 0, libraryCount: 0, showEmptyOnboarding: false),
        );
      }),
    );
    final l10n = context.l10n;
    final String greetingText = l10n.homeGreetingReader(
      l10n.homeGreetingPhraseForHour(DateTime.now().hour),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final HomePageLayoutTier layoutTier = homePageLayoutTierForWidth(
          viewportWidth,
        );
        final double horizontalPadding = homeContentHorizontalPadding(
          layoutTier,
        );
        final double innerMaxWidth = homeInnerContentMaxWidth(
          layoutTier,
          viewportWidth,
        );

        final Widget headerSection = HomePageHeaderSection(
          layoutTier: layoutTier,
          horizontalPadding: horizontalPadding,
          contentMaxWidth: innerMaxWidth,
          onOpenNavigation: appShellPageNavigationOpener(context),
        );
        final Widget header = KeyedSubtree(
          key: _headerMeasureKey,
          child: headerSection,
        );

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (_headerExtent == null)
              SliverToBoxAdapter(child: header)
            else
              SliverPersistentHeader(
                pinned: true,
                delegate: HomePinnedHeaderDelegate(
                  extent: _headerExtent!,
                  child: header,
                ),
              ),
            SliverToBoxAdapter(
              child: PageContentWidthAlign(
                horizontalPadding: horizontalPadding,
                maxWidth: innerMaxWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: tokens.layout.contentVerticalPadding,
                    bottom: tokens.layout.contentAreaPadding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        greetingText,
                        style: homePageSubtitleStyle(context.hentai),
                      ),
                      SizedBox(height: tokens.spacing.lg),
                      HomeLibraryAlertStack(enabled: deferredSectionsReady),
                      SizedBox(height: tokens.spacing.lg),
                      HomePageContinueReadingSection(
                        layoutTier: layoutTier,
                        enabled: deferredSectionsReady,
                      ),
                      SizedBox(height: tokens.spacing.xl),
                      HomeRecentlyAddedSection(
                        layoutTier: layoutTier,
                        enabled: deferredSectionsReady,
                      ),
                      SizedBox(height: tokens.spacing.xl),
                      HomePageHeroSection(
                        layoutTier: layoutTier,
                        comicCount: homeCountsLeaf.comicCount,
                        showEmptyOnboarding: homeCountsLeaf.showEmptyOnboarding,
                        enableHeavyStats: deferredSectionsReady,
                      ),
                      SizedBox(height: tokens.spacing.xl + 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
