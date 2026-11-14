import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

typedef _Candidate = ({String name, bool smartMatched});
const _candidates = <_Candidate>[
  (name: '深海', smartMatched: true),
  (name: '图书馆', smartMatched: false),
  (name: 'Python', smartMatched: false),
  (name: '用于验证窄窗口和大字体的超长标签名称 Long candidate label', smartMatched: true),
];

/// Widgetbook demo with local selection + smart facet candidates.
class Md3eNamedFacetMultiSelectFieldPreview extends StatefulWidget {
  const Md3eNamedFacetMultiSelectFieldPreview({super.key});

  @override
  State<Md3eNamedFacetMultiSelectFieldPreview> createState() =>
      _Md3eNamedFacetMultiSelectFieldPreviewState();
}

class _Md3eNamedFacetMultiSelectFieldPreviewState
    extends State<Md3eNamedFacetMultiSelectFieldPreview> {
  final List<String> _selected = <String>[
    '深海',
    '已有作者',
    '偶像大师',
    'Clannad',
    'fate stay night',
    'コードギアス 反逆のルルーシュ',
    '刀剑神域',
    '原神',
  ];

  @override
  Widget build(BuildContext context) {
    final String state = context.knobs.object.dropdown(
      label: 'Candidates',
      options: <String>['Loaded', 'Loading', 'Error', 'Empty'],
    );
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Align(
        alignment: Alignment.topCenter,
        child: FacetMultiSelectField<_Candidate>(
          label: '作者',
          selectedNames: _selected,
          onAdd: (String name) {
            if (_selected.contains(name)) {
              return;
            }
            setState(() => _selected.add(name));
          },
          onRemove: (String name) {
            setState(() => _selected.remove(name));
          },
          onClearAll: () => setState(() => _selected.clear()),
          items: state == 'Empty' ? const <_Candidate>[] : _candidates,
          isLoading: state == 'Loading',
          hasLoadError: state == 'Error',
          onRetry: () => setState(() {}),
          resolveName: (_Candidate c) => c.name,
          resolveSmartMatched: (_Candidate c) => c.smartMatched,
          smartMatchedTooltip: context.l10n.smartFacetMatchHintTooltip,
          copy: NamedFacetMultiSelectCopy(
            listLoadFailed: context.l10n.formAuthorListLoadFailed,
            emptyCatalog: context.l10n.formAuthorEmptyCatalog,
            emptyRemaining: context.l10n.formAuthorEmptyRemaining,
            retryLabel: context.l10n.commonRetry,
          ),
          maxWidth: 480,
        ),
      ),
    );
  }
}
