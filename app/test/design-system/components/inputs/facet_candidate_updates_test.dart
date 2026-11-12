import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../../support/pump_design_system_app.dart';

typedef _Candidates = ({List<String> items, bool loading, bool error});

const _copy = NamedFacetMultiSelectCopy(
  listLoadFailed: '加载失败',
  emptyCatalog: '目录为空',
  emptyRemaining: '无剩余',
  retryLabel: '重试',
);

Future<void> _pumpField(
  WidgetTester tester,
  ValueNotifier<_Candidates> candidates,
  List<String> selected, {
  VoidCallback? retry,
}) => pumpDesignSystemApp(
  tester,
  home: Center(
    child: SizedBox(
      width: 360,
      child: ValueListenableBuilder<_Candidates>(
        valueListenable: candidates,
        builder: (context, value, _) => FacetMultiSelectField<String>(
          label: '候选',
          items: value.items,
          isLoading: value.loading,
          hasLoadError: value.error,
          selectedNames: selected,
          onAdd: selected.add,
          onRemove: selected.remove,
          onRetry: retry ?? () {},
          resolveName: (name) => name,
          copy: _copy,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('open overlay follows loading, error, retry and new data', (
    tester,
  ) async {
    final candidates = ValueNotifier<_Candidates>((
      items: [],
      loading: true,
      error: false,
    ));
    addTearDown(candidates.dispose);
    final selected = <String>[];
    var retries = 0;
    await _pumpField(
      tester,
      candidates,
      selected,
      retry: () {
        retries++;
        candidates.value = (items: ['深海', '图书馆'], loading: false, error: false);
      },
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    candidates.value = (items: [], loading: false, error: true);
    await tester.pumpAndSettle();
    expect(find.text('加载失败'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(retries, 1);
    expect(find.text('图书馆'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    await tester.enterText(find.byType(EditableText), 'tsg');
    await tester.pumpAndSettle();
    expect(find.text('深海'), findsNothing);
    expect(find.text('图书馆'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(selected, ['图书馆']);
  });

  testWidgets('changed candidates keep query and reset keyboard highlight', (
    tester,
  ) async {
    final candidates = ValueNotifier<_Candidates>((
      items: ['Alpha', 'Alpine'],
      loading: false,
      error: false,
    ));
    addTearDown(candidates.dispose);
    final selected = <String>[];
    await _pumpField(tester, candidates, selected);
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'al');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    candidates.value = (items: ['Algebra'], loading: false, error: false);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'al',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(selected, ['Algebra']);
  });

  testWidgets('empty catalog and no remaining candidates have distinct copy', (
    tester,
  ) async {
    final candidates = ValueNotifier<_Candidates>((
      items: [],
      loading: false,
      error: false,
    ));
    addTearDown(candidates.dispose);
    await _pumpField(tester, candidates, ['已有']);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text('目录为空'), findsOneWidget);
    candidates.value = (items: ['已有'], loading: false, error: false);
    await tester.pumpAndSettle();
    expect(find.text('无剩余'), findsOneWidget);
  });

  testWidgets('IME composing keys do not select candidates or remove chips', (
    tester,
  ) async {
    final candidates = ValueNotifier<_Candidates>((
      items: ['深海'],
      loading: false,
      error: false,
    ));
    addTearDown(candidates.dispose);
    final selected = <String>['已有'];
    await _pumpField(tester, candidates, selected);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'shen',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(selected, ['已有']);
    expect(find.byKey(FacetMultiSelectField.menuPanelKey), findsOneWidget);
  });
}
