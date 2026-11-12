import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/domain/smart_facet_match.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/library_facet_multi_select_field.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_form.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../../support/pump_app.dart';

const ComicMetadataSmartFacetScope _scope = (
  comicId: 'comic-1',
  title: '标题',
  resourcePath: '/library/a.cbz',
  seriesId: null,
);

const List<SmartFacetMatchCandidate> _candidates = <SmartFacetMatchCandidate>[
  (name: '深海', attachmentCount: 2, smartMatched: true),
  (name: '图书馆', attachmentCount: 5, smartMatched: false),
];

List<Override> _overrides() {
  return <Override>[
    authorsSmartForComicMetadataFormProvider(_scope)
        .overrideWith((Ref ref) async => _candidates),
  ];
}

Future<void> _pumpField(
  WidgetTester tester, {
  required List<String> selected,
  required ValueChanged<String> onAdd,
  required ValueChanged<String> onRemove,
  VoidCallback? onClearAll,
}) async {
  await pumpApp(
    tester,
    overrides: _overrides(),
    home: Center(
      child: SizedBox(
        width: 360,
        child: LibraryFacetMultiSelectField(
          kind: NamedFacetFormKind.author,
          label: '作者',
          selectedNames: selected,
          onAdd: onAdd,
          onRemove: onRemove,
          onClearAll: onClearAll,
          scope: _scope,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('渲染已有 chip 并从候选浮层回传 onAdd', (WidgetTester tester) async {
    final List<String> selected = <String>['已有作者'];
    await _pumpField(
      tester,
      selected: selected,
      onAdd: selected.add,
      onRemove: selected.remove,
    );

    expect(find.text('已有作者'), findsOneWidget);

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深海').last);
    await tester.pumpAndSettle();

    expect(selected, <String>['已有作者', '深海']);
  });

  testWidgets('清空按钮回传 onClearAll', (WidgetTester tester) async {
    int cleared = 0;
    await _pumpField(
      tester,
      selected: const <String>['已有作者'],
      onAdd: (_) {},
      onRemove: (_) {},
      onClearAll: () => cleared++,
    );

    final Finder clearAll = find.byKey(
      const Key('_named_facet_multi_select_clear_all_button'),
    );
    expect(clearAll, findsOneWidget);

    await tester.tap(clearAll);
    await tester.pumpAndSettle();

    expect(cleared, 1);
  });

  testWidgets('删除 chip 回传 onRemove', (WidgetTester tester) async {
    final List<String> selected = <String>['已有作者'];
    await _pumpField(
      tester,
      selected: selected,
      onAdd: selected.add,
      onRemove: selected.remove,
    );

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
  });
}
