import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/domain/comic/smart_facet_match.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_named_facet_multi_select_copy.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_named_facet_multi_select_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod/misc.dart' show Override, ProviderListenable;

import '../../../../support/pump_md3e_app.dart';

final _testItemsProvider = Provider<AsyncValue<List<SmartFacetMatchCandidate>>>(
  (Ref ref) => const AsyncData<List<SmartFacetMatchCandidate>>(<
    SmartFacetMatchCandidate
  >[
    (name: '深海', attachmentCount: 2, smartMatched: true),
    (name: '图书馆', attachmentCount: 5, smartMatched: false),
    (name: 'Python', attachmentCount: 1, smartMatched: false),
  ]),
);

void main() {
  testWidgets('opens menu on focus and adds chip from candidate', (
    WidgetTester tester,
  ) async {
    final List<String> selected = <String>[];

    await pumpMd3eApp(
      tester,
      overrides: <Override>[
        _testItemsProvider.overrideWith(
          (Ref ref) => const AsyncData<List<SmartFacetMatchCandidate>>(<
            SmartFacetMatchCandidate
          >[
            (name: '深海', attachmentCount: 2, smartMatched: true),
            (name: '图书馆', attachmentCount: 5, smartMatched: false),
            (name: 'Python', attachmentCount: 1, smartMatched: false),
          ]),
        ),
      ],
      home: Center(
        child: SizedBox(
          width: 360,
          child: Md3eNamedFacetMultiSelectField<SmartFacetMatchCandidate>(
            label: '作者',
            selectedNames: selected,
            onAdd: selected.add,
            onRemove: selected.remove,
            itemsProvider: _testItemsProvider,
            onRetry: () {},
            resolveName: (SmartFacetMatchCandidate c) => c.name,
            resolveSmartMatched: (SmartFacetMatchCandidate c) => c.smartMatched,
            smartMatchedTooltip: '由智能匹配推荐',
            copy: const Md3eNamedFacetMultiSelectCopy(
              listLoadFailed: '加载失败',
              emptyCatalog: '目录为空',
              emptyRemaining: '无剩余',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    expect(
      find.byKey(Md3eNamedFacetMultiSelectField.menuPanelKey),
      findsOneWidget,
    );
    expect(find.text('深海'), findsWidgets);

    await tester.tap(find.text('深海').last);
    await tester.pumpAndSettle();

    expect(selected, <String>['深海']);
    expect(find.text('深海'), findsWidgets);
    expect(find.byIcon(Symbols.auto_awesome), findsOneWidget);
  });

  testWidgets('Enter commits free-text name', (WidgetTester tester) async {
    final List<String> selected = <String>[];

    await pumpMd3eApp(
      tester,
      overrides: <Override>[
        _testItemsProvider.overrideWith(
          (Ref ref) => const AsyncData<List<SmartFacetMatchCandidate>>(<
            SmartFacetMatchCandidate
          >[
            (name: '深海', attachmentCount: 2, smartMatched: true),
            (name: '图书馆', attachmentCount: 5, smartMatched: false),
            (name: 'Python', attachmentCount: 1, smartMatched: false),
          ]),
        ),
      ],
      home: Center(
        child: SizedBox(
          width: 360,
          child: Md3eNamedFacetMultiSelectField<SmartFacetMatchCandidate>(
            label: '标签',
            selectedNames: selected,
            onAdd: selected.add,
            onRemove: selected.remove,
            itemsProvider: _testItemsProvider,
            onRetry: () {},
            resolveName: (SmartFacetMatchCandidate c) => c.name,
            copy: const Md3eNamedFacetMultiSelectCopy(
              listLoadFailed: '加载失败',
              emptyCatalog: '目录为空',
              emptyRemaining: '无剩余',
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
}
