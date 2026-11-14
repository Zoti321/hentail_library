import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../support/pump_design_system_app.dart';

typedef _Candidate = ({String name, int attachmentCount, bool smartMatched});

const _testItems = <_Candidate>[
  (name: '深海', attachmentCount: 2, smartMatched: true),
  (name: '图书馆', attachmentCount: 5, smartMatched: false),
  (name: 'Python', attachmentCount: 1, smartMatched: false),
];

void main() {
  testWidgets('opens menu on focus and adds chip from candidate', (
    WidgetTester tester,
  ) async {
    final List<String> selected = <String>[];

    await pumpDesignSystemApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 360,
          child: FacetMultiSelectField<_Candidate>(
            label: '作者',
            selectedNames: selected,
            onAdd: selected.add,
            onRemove: selected.remove,
            items: _testItems,
            onRetry: () {},
            resolveName: (_Candidate c) => c.name,
            resolveSmartMatched: (_Candidate c) => c.smartMatched,
            smartMatchedTooltip: '由智能匹配推荐',
            copy: const NamedFacetMultiSelectCopy(
              listLoadFailed: '加载失败',
              emptyCatalog: '目录为空',
              emptyRemaining: '无剩余',
              retryLabel: '重试',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    expect(find.byKey(FacetMultiSelectField.menuPanelKey), findsOneWidget);
    expect(find.text('深海'), findsWidgets);

    await tester.tap(find.text('深海').last);
    await tester.pumpAndSettle();

    expect(selected, <String>['深海']);
    expect(find.text('深海'), findsWidgets);
    expect(find.byIcon(Symbols.auto_awesome), findsOneWidget);
  });

  testWidgets('selected rows stay visible and toggle with click and Tab', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDesignSystemApp(
      tester,
      home: const Center(
        child: SizedBox(
          width: 360,
          child: _NamedFacetMultiSelectTestHarness(initialSelected: ['深海']),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.byIcon(Symbols.check_box), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.checked == true,
      ),
      findsOneWidget,
    );
    expect(find.text('深海'), findsNWidgets(2));
    await tester.tap(find.text('深海').last);
    await tester.pumpAndSettle();
    expect(find.byIcon(Symbols.check_box), findsNothing);
    expect(find.text('深海'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byIcon(Symbols.check_box), findsOneWidget);
    expect(find.text('深海'), findsNWidgets(2));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byIcon(Symbols.check_box), findsNothing);
    expect(find.byKey(FacetMultiSelectField.menuPanelKey), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('submitting an existing name does not duplicate a chip', (
    tester,
  ) async {
    await pumpDesignSystemApp(
      tester,
      home: const Center(
        child: SizedBox(
          width: 360,
          child: _NamedFacetMultiSelectTestHarness(initialSelected: ['深海']),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), '深海');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('深海'), findsNWidgets(2));
  });

  testWidgets('menu avoids keyboard insets and uses constrained field width', (
    tester,
  ) async {
    await pumpDesignSystemApp(
      tester,
      home: const MediaQuery(
        data: MediaQueryData(
          size: Size(800, 600),
          viewInsets: EdgeInsets.only(bottom: 350),
        ),
        child: Center(
          child: SizedBox(
            width: 300,
            child: _NamedFacetMultiSelectTestHarness(initialSelected: []),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    final panel = tester.getRect(
      find.byKey(FacetMultiSelectField.menuPanelKey),
    );
    expect(panel.bottom, lessThanOrEqualTo(250));
    expect(panel.width, 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home edits query without changing the candidate selected by Tab',
    (tester) async {
      await pumpDesignSystemApp(
        tester,
        home: const Center(
          child: SizedBox(
            width: 360,
            child: _NamedFacetMultiSelectTestHarness(initialSelected: []),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Python');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.byIcon(Symbols.check_box), findsOneWidget);
      expect(find.text('Python'), findsNWidgets(2));
    },
  );

  testWidgets('clear all trailing button removes every chip', (
    WidgetTester tester,
  ) async {
    await pumpDesignSystemApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 360,
          child: _NamedFacetMultiSelectTestHarness(
            initialSelected: const <String>['已有', '第二个'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(FacetMultiSelectField.clearAllButtonKey), findsOneWidget);

    await tester.tap(find.byKey(FacetMultiSelectField.clearAllButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(FacetMultiSelectField.clearAllButtonKey), findsNothing);
  });

  testWidgets('Enter commits free-text name', (WidgetTester tester) async {
    final List<String> selected = <String>[];

    await pumpDesignSystemApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 360,
          child: FacetMultiSelectField<_Candidate>(
            label: '标签',
            selectedNames: selected,
            onAdd: selected.add,
            onRemove: selected.remove,
            items: _testItems,
            onRetry: () {},
            resolveName: (_Candidate c) => c.name,
            copy: const NamedFacetMultiSelectCopy(
              listLoadFailed: '加载失败',
              emptyCatalog: '目录为空',
              emptyRemaining: '无剩余',
              retryLabel: '重试',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), '新标签');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(selected, <String>['新标签']);
  });

  testWidgets('arrow down and Enter select highlighted candidate', (
    WidgetTester tester,
  ) async {
    final List<String> selected = <String>[];

    await pumpDesignSystemApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 360,
          child: FacetMultiSelectField<_Candidate>(
            label: '作者',
            selectedNames: selected,
            onAdd: selected.add,
            onRemove: selected.remove,
            items: _testItems,
            onRetry: () {},
            resolveName: (_Candidate c) => c.name,
            copy: const NamedFacetMultiSelectCopy(
              listLoadFailed: '加载失败',
              emptyCatalog: '目录为空',
              emptyRemaining: '无剩余',
              retryLabel: '重试',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected, <String>['图书馆']);
  });

  testWidgets('Escape closes menu overlay', (WidgetTester tester) async {
    await pumpDesignSystemApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 360,
          child: FacetMultiSelectField<_Candidate>(
            label: '作者',
            selectedNames: const <String>[],
            onAdd: (_) {},
            onRemove: (_) {},
            items: _testItems,
            onRetry: () {},
            resolveName: (_Candidate c) => c.name,
            copy: const NamedFacetMultiSelectCopy(
              listLoadFailed: '加载失败',
              emptyCatalog: '目录为空',
              emptyRemaining: '无剩余',
              retryLabel: '重试',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.byKey(FacetMultiSelectField.menuPanelKey), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.byKey(FacetMultiSelectField.menuPanelKey), findsNothing);
  });

  testWidgets('Backspace on empty input removes last chip', (
    WidgetTester tester,
  ) async {
    final List<String> selected = <String>['第一个', '第二个'];

    await pumpDesignSystemApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 360,
          child: FacetMultiSelectField<_Candidate>(
            label: '标签',
            selectedNames: selected,
            onAdd: selected.add,
            onRemove: selected.remove,
            items: _testItems,
            onRetry: () {},
            resolveName: (_Candidate c) => c.name,
            copy: const NamedFacetMultiSelectCopy(
              listLoadFailed: '加载失败',
              emptyCatalog: '目录为空',
              emptyRemaining: '无剩余',
              retryLabel: '重试',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(selected, <String>['第一个']);
  });
}

class _NamedFacetMultiSelectTestHarness extends StatefulWidget {
  const _NamedFacetMultiSelectTestHarness({required this.initialSelected});

  final List<String> initialSelected;

  @override
  State<_NamedFacetMultiSelectTestHarness> createState() =>
      _NamedFacetMultiSelectTestHarnessState();
}

class _NamedFacetMultiSelectTestHarnessState
    extends State<_NamedFacetMultiSelectTestHarness> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.of(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return FacetMultiSelectField<_Candidate>(
      label: '标签',
      selectedNames: _selected,
      onAdd: (String name) => setState(() => _selected.add(name)),
      onRemove: (String name) => setState(() => _selected.remove(name)),
      onClearAll: () => setState(() => _selected.clear()),
      items: _testItems,
      onRetry: () {},
      resolveName: (_Candidate c) => c.name,
      copy: const NamedFacetMultiSelectCopy(
        listLoadFailed: '加载失败',
        emptyCatalog: '目录为空',
        emptyRemaining: '无剩余',
        retryLabel: '重试',
      ),
    );
  }
}
