import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/view_models/selected_paths_page_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/selected_paths_page.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('Selected paths responsive layout', () {
    testWidgets('compact page shows back and title without overflow', (
      WidgetTester tester,
    ) async {
      await _pumpSelectedPathsPage(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('选中路径'));
      expect(title.style?.fontSize, 18);
      expect(find.text('管理本地漫画根目录，支持批量选择'), findsNothing);
      expect(find.textContaining('路径 '), findsNothing);
      expect(find.text('清空选择'), findsNothing);
      expect(find.byTooltip('返回'), findsOneWidget);
      expect(find.text('添加路径'), findsOneWidget);
    });

    testWidgets('medium page keeps medium title and add path', (
      WidgetTester tester,
    ) async {
      await _pumpSelectedPathsPage(tester, viewportWidth: 700);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('选中路径'));
      expect(title.style?.fontSize, 22);
      expect(find.text('管理本地漫画根目录，支持批量选择'), findsNothing);
      expect(find.text('添加路径'), findsOneWidget);
    });

    testWidgets('expanded page uses expanded title size', (
      WidgetTester tester,
    ) async {
      await _pumpSelectedPathsPage(tester, viewportWidth: 1200);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('选中路径'));
      expect(title.style?.fontSize, 26);
    });
  });
}

Future<void> _pumpSelectedPathsPage(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _selectedPathsPageTestOverrides(),
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: viewportWidth,
            height: 800,
            child: const SelectedPathsPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Override> _selectedPathsPageTestOverrides() {
  return <Override>[
    selectedPathsPageProvider.overrideWith(_FakeSelectedPathsPageNotifier.new),
  ];
}

class _FakeSelectedPathsPageNotifier extends SelectedPathsPageNotifier {
  @override
  Future<SelectedPathsPageState> build() async {
    return const SelectedPathsPageState(paths: <String>['C:\\comics']);
  }
}
