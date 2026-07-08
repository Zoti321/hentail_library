import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/metadata/view_models/author_management_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/metadata_management_page.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/author_management_panel.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_row_actions.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('Metadata responsive layout', () {
    testWidgets('compact page hides top subtitle without overflow', (
      WidgetTester tester,
    ) async {
      await _pumpMetadataPage(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      expect(find.text('管理作者与标签'), findsNothing);
    });

    testWidgets('medium page shows top subtitle', (WidgetTester tester) async {
      await _pumpMetadataPage(tester, viewportWidth: 700);

      expect(tester.takeException(), isNull);
      expect(find.text('管理作者与标签'), findsOneWidget);
    });

    testWidgets('compact author panel uses vertical header and overflow actions', (
      WidgetTester tester,
    ) async {
      await _pumpAuthorPanel(
        tester,
        viewportWidth: 360,
        layoutTier: MetadataLayoutTier.compact,
      );

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('作者管理'));
      expect(title.style?.fontSize, 18);
      expect(find.textContaining('Ctrl+N'), findsNothing);
      expect(
        find.byWidgetPredicate((Widget widget) => widget is PopupMenuButton),
        findsNWidgets(2),
      );
    });

    testWidgets('expanded author panel keeps full add button label', (
      WidgetTester tester,
    ) async {
      await _pumpAuthorPanel(
        tester,
        viewportWidth: 1200,
        layoutTier: MetadataLayoutTier.expanded,
      );

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('作者管理'));
      expect(title.style?.fontSize, 26);
      expect(find.textContaining('Ctrl+N'), findsOneWidget);
      expect(
        find.byWidgetPredicate((Widget widget) => widget is PopupMenuButton),
        findsNothing,
      );
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
        theme: buildAppTheme(Brightness.light),
        routerConfig: GoRouter(
          initialLocation: '/metadata?tab=authors',
          routes: <RouteBase>[
            GoRoute(
              path: '/metadata',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(
                  body: MetadataManagementPage(),
                );
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
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: metadataInnerContentMaxWidth(layoutTier, viewportWidth),
            height: 800,
            child: AuthorManagementPanel(layoutTier: layoutTier),
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
      (Ref ref) => Future<List<Tag>>.value(<Tag>[
        Tag(name: '标签 A'),
      ]),
    ),
  ];
}
