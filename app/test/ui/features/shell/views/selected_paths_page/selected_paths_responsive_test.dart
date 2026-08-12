import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
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
      final Text title = tester.widget<Text>(find.text('本地库'));
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
      final Text title = tester.widget<Text>(find.text('本地库'));
      expect(title.style?.fontSize, 22);
      expect(find.text('管理本地漫画根目录，支持批量选择'), findsNothing);
      expect(find.text('添加路径'), findsOneWidget);
    });

    testWidgets('expanded page uses expanded title size', (
      WidgetTester tester,
    ) async {
      await _pumpSelectedPathsPage(tester, viewportWidth: 1200);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('本地库'));
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
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
    currentLibraryProvider.overrideWith(_FakeCurrentLibraryNotifier.new),
  ];
}

class _FakeSelectedPathsPageNotifier extends SelectedPathsPageNotifier {
  @override
  Future<SelectedPathsPageState> build() async {
    return const SelectedPathsPageState(paths: <String>['C:\\comics']);
  }
}

class _FakeCurrentLibraryNotifier extends CurrentLibraryNotifier {
  @override
  Future<CurrentLibraryState> build() async {
    const LocalLibrary library = (
      libraryId: 'lib1',
      kind: 'local',
      rootPath: 'C:\\comics',
      name: 'comics',
      enabledFormatGroups: FormatGroup.all,
      username: '',
      allowHttp: false,
    );
    return const CurrentLibraryState(
      libraries: <LocalLibrary>[library],
      currentId: 'lib1',
    );
  }
}
