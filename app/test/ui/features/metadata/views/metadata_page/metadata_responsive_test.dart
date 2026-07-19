import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/ui/core/widgets/chrome/content_switcher_bottom_bar.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/count_digit_chip.dart';
import 'package:hentai_library/ui/features/metadata/view_models/author_management_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/metadata_management_page.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/author_management_panel.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('Metadata responsive layout', () {
    testWidgets(
      'compact page uses bottom bar, header count chip, and no header tabs',
      (WidgetTester tester) async {
        await _pumpMetadataPage(tester, viewportWidth: 360);

        expect(tester.takeException(), isNull);
        expect(find.text('管理'), findsOneWidget);
        expect(find.byType(CapsuleTabBar), findsNothing);
        expect(find.byType(ContentSwitcherBottomBar), findsOneWidget);
        expect(find.byType(CountDigitChip), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('共 2 条'), findsNothing);
        expect(find.text('作者'), findsOneWidget);
        expect(find.text('标签'), findsOneWidget);
      },
    );

    testWidgets('expanded page uses capsule tabs and add icon tooltip', (
      WidgetTester tester,
    ) async {
      await _pumpMetadataPage(tester, viewportWidth: 1200);

      expect(tester.takeException(), isNull);
      expect(find.text('管理'), findsOneWidget);
      expect(find.byType(CapsuleTabBar), findsOneWidget);
      expect(find.byType(ContentSwitcherBottomBar), findsNothing);
      expect(find.byType(CountDigitChip), findsNothing);
      expect(find.text('管理作者与标签'), findsNothing);
      expect(find.byTooltip('添加作者'), findsOneWidget);
      expect(find.textContaining('Ctrl+N'), findsNothing);
    });

    testWidgets(
      'compact author panel uses overflow actions without bulk delete',
      (WidgetTester tester) async {
        await _pumpAuthorPanel(
          tester,
          viewportWidth: 360,
          layoutTier: MetadataLayoutTier.compact,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('作者管理'), findsNothing);
        expect(find.byTooltip('删除已选'), findsNothing);
        expect(find.byTooltip('更多操作'), findsNWidgets(2));
        expect(find.byType(CustomPopupMenu), findsNWidgets(2));
        expect(find.byType(PopupMenuButton), findsNothing);
      },
    );

    testWidgets('expanded author panel keeps row actions in card layout', (
      WidgetTester tester,
    ) async {
      await _pumpAuthorPanel(
        tester,
        viewportWidth: 1200,
        layoutTier: MetadataLayoutTier.expanded,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('作者管理'), findsNothing);
      expect(find.byTooltip('删除已选'), findsNothing);
      expect(
        find.byWidgetPredicate((Widget widget) => widget is PopupMenuButton),
        findsNothing,
      );
      expect(find.byType(CustomPopupMenu), findsNothing);
      expect(find.byTooltip('重命名'), findsNWidgets(2));
    });
  });
}

Future<void> _pumpMetadataPage(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _metadataTestOverrides(),
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        routerConfig: GoRouter(
          initialLocation: '/metadata?tab=authors',
          routes: <RouteBase>[
            GoRoute(
              path: '/metadata',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(body: MetadataManagementPage());
              },
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAuthorPanel(
  WidgetTester tester, {
  required double viewportWidth,
  required MetadataLayoutTier layoutTier,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _metadataTestOverrides(),
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              AuthorManagementSliverGroup(
                layoutTier: layoutTier,
                viewportWidth: viewportWidth,
                horizontalPadding: metadataContentHorizontalPadding(layoutTier),
                contentMaxWidth: metadataInnerContentMaxWidth(
                  layoutTier,
                  viewportWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Override> _metadataTestOverrides() {
  return <Override>[
    allAuthorsProvider.overrideWith(
      (Ref ref) => Stream<List<Author>>.value(<Author>[
        Author(name: '作者 A'),
        Author(name: '作者 B'),
      ]),
    ),
    allTagsProvider.overrideWith(
      (Ref ref) => Future<List<Tag>>.value(<Tag>[Tag(name: '标签 A')]),
    ),
  ];
}
