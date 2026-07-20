import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/form/multi_select.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

final _catalogProvider = Provider<AsyncValue<List<String>>>(
  (Ref ref) =>
      const AsyncData<List<String>>(<String>['alpha', 'beta', 'gamma']),
);

void main() {
  Future<void> pumpMultiSelect(
    WidgetTester tester, {
    List<String> selectedNames = const <String>[],
    ValueChanged<String>? onAdd,
    ValueChanged<String>? onRemove,
    ProviderListenable<AsyncValue<List<String>>>? itemsProvider,
    VoidCallback? onRetry,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: MultiSelect<String>(
                label: '标签',
                icon: LucideIcons.tag,
                selectedNames: selectedNames,
                onAdd: onAdd ?? (_) {},
                onRemove: onRemove ?? (_) {},
                itemsProvider: itemsProvider ?? _catalogProvider,
                onRetry: onRetry ?? () {},
                resolveName: (String name) => name,
                copy: const MultiSelectCopy(
                  inputPlaceholder: '选择或输入标签…',
                  listLoadFailed: '标签列表加载失败',
                  emptyCatalog: '暂无标签',
                  emptyRemaining: '没有更多可选',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows selected names as removable chips in the field', (
    WidgetTester tester,
  ) async {
    await pumpMultiSelect(
      tester,
      selectedNames: const <String>['alpha', 'beta'],
    );

    expect(find.byType(OutlinedMetaChip), findsNWidgets(2));
    expect(find.widgetWithText(OutlinedMetaChip, 'alpha'), findsOneWidget);
    expect(find.widgetWithText(OutlinedMetaChip, 'beta'), findsOneWidget);
    expect(find.text('已选 2 个'), findsNothing);
    expect(find.byIcon(Icons.close), findsNWidgets(2));
  });

  testWidgets('remove chip calls onRemove and returns name to dropdown', (
    WidgetTester tester,
  ) async {
    final List<String> selected = <String>['alpha', 'beta'];
    final List<String> removed = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return MultiSelect<String>(
                    label: '标签',
                    icon: LucideIcons.tag,
                    selectedNames: selected,
                    onAdd: (String name) {
                      setState(() => selected.add(name));
                    },
                    onRemove: (String name) {
                      removed.add(name);
                      setState(() => selected.remove(name));
                    },
                    itemsProvider: _catalogProvider,
                    onRetry: () {},
                    resolveName: (String name) => name,
                    copy: const MultiSelectCopy(
                      inputPlaceholder: '选择或输入标签…',
                      listLoadFailed: '标签列表加载失败',
                      emptyCatalog: '暂无标签',
                      emptyRemaining: '没有更多可选',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(removed, <String>['alpha']);
    expect(find.widgetWithText(OutlinedMetaChip, 'alpha'), findsNothing);
    expect(find.widgetWithText(OutlinedMetaChip, 'beta'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.text('alpha'), findsOneWidget);
  });

  testWidgets('dropdown matches field width and excludes selected names', (
    WidgetTester tester,
  ) async {
    await pumpMultiSelect(tester, selectedNames: const <String>['alpha']);

    final Finder fieldSurface = find.byKey(MultiSelect.fieldSurfaceKey);
    final Size fieldSize = tester.getSize(fieldSurface);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(MultiSelect.menuPanelKey),
        matching: find.text('alpha'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(MultiSelect.menuPanelKey),
        matching: find.text('beta'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(MultiSelect.menuPanelKey),
        matching: find.text('gamma'),
      ),
      findsOneWidget,
    );

    final Size menuSize = tester.getSize(find.byKey(MultiSelect.menuPanelKey));
    expect(menuSize.width, closeTo(fieldSize.width, 0.5));
  });

  testWidgets('selecting dropdown row calls onAdd', (
    WidgetTester tester,
  ) async {
    final List<String> added = <String>[];

    await pumpMultiSelect(
      tester,
      selectedNames: const <String>['alpha'],
      onAdd: added.add,
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(MultiSelect.menuPanelKey),
        matching: find.text('beta'),
      ),
    );
    await tester.pumpAndSettle();

    expect(added, <String>['beta']);
  });

  testWidgets(
    'selecting a dropdown row removes it from open menu immediately',
    (WidgetTester tester) async {
      final List<String> selected = <String>['alpha'];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAppTheme(Brightness.light),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return MultiSelect<String>(
                      label: '标签',
                      icon: LucideIcons.tag,
                      selectedNames: selected,
                      onAdd: (String name) {
                        setState(() => selected.add(name));
                      },
                      onRemove: (String name) {
                        setState(() => selected.remove(name));
                      },
                      itemsProvider: _catalogProvider,
                      onRetry: () {},
                      resolveName: (String name) => name,
                      copy: const MultiSelectCopy(
                        inputPlaceholder: '选择或输入标签…',
                        listLoadFailed: '标签列表加载失败',
                        emptyCatalog: '暂无标签',
                        emptyRemaining: '没有更多可选',
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(MultiSelect.menuPanelKey),
          matching: find.text('beta'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(MultiSelect.menuPanelKey),
          matching: find.text('beta'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(MultiSelect.menuPanelKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(MultiSelect.menuPanelKey),
          matching: find.text('beta'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(MultiSelect.menuPanelKey),
          matching: find.text('gamma'),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedMetaChip, 'beta'), findsOneWidget);
    },
  );

  testWidgets('submitting inline input calls onAdd and clears the field', (
    WidgetTester tester,
  ) async {
    final List<String> added = <String>[];

    await pumpMultiSelect(tester, onAdd: added.add);

    await tester.enterText(find.byType(TextField), '  new-tag  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(added, <String>['new-tag']);
    expect(find.widgetWithText(TextField, 'new-tag'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('shows loading and error UI for catalog AsyncValue', (
    WidgetTester tester,
  ) async {
    final Provider<AsyncValue<List<String>>> loadingProvider =
        Provider<AsyncValue<List<String>>>(
          (Ref ref) => const AsyncLoading<List<String>>(),
        );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: MultiSelect<String>(
                label: '标签',
                icon: LucideIcons.tag,
                selectedNames: const <String>[],
                onAdd: (_) {},
                onRemove: (_) {},
                itemsProvider: loadingProvider,
                onRetry: () {},
                resolveName: (String name) => name,
                copy: const MultiSelectCopy(
                  inputPlaceholder: '选择或输入标签…',
                  listLoadFailed: '标签列表加载失败',
                  emptyCatalog: '暂无标签',
                  emptyRemaining: '没有更多可选',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Progress indicators animate forever; do not pumpAndSettle.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    var retried = false;
    final Provider<AsyncValue<List<String>>> errorProvider =
        Provider<AsyncValue<List<String>>>(
          (Ref ref) =>
              AsyncError<List<String>>(Exception('boom'), StackTrace.current),
        );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: MultiSelect<String>(
                label: '标签',
                icon: LucideIcons.tag,
                selectedNames: const <String>[],
                onAdd: (_) {},
                onRemove: (_) {},
                itemsProvider: errorProvider,
                onRetry: () => retried = true,
                resolveName: (String name) => name,
                copy: const MultiSelectCopy(
                  inputPlaceholder: '选择或输入标签…',
                  listLoadFailed: '标签列表加载失败',
                  emptyCatalog: '暂无标签',
                  emptyRemaining: '没有更多可选',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('标签列表加载失败'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(retried, isTrue);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(find.text('加载失败'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(MultiSelect.menuPanelKey),
        matching: find.text('重试'),
      ),
      findsOneWidget,
    );
  });
}
