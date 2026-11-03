import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/domain/comic/smart_facet_match.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_named_facet_multi_select_copy.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_named_facet_multi_select_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

final Provider<AsyncValue<List<SmartFacetMatchCandidate>>>
    md3eNamedFacetMultiSelectPreviewProvider =
    Provider<AsyncValue<List<SmartFacetMatchCandidate>>>(
      (Ref ref) => const AsyncData<List<SmartFacetMatchCandidate>>(<
        SmartFacetMatchCandidate
      >[
        (name: '深海', attachmentCount: 3, smartMatched: true),
        (name: '图书馆', attachmentCount: 8, smartMatched: false),
        (name: 'Python', attachmentCount: 1, smartMatched: false),
      ]),
    );

/// Widgetbook demo with local selection + smart facet candidates.
class Md3eNamedFacetMultiSelectFieldPreview extends ConsumerStatefulWidget {
  const Md3eNamedFacetMultiSelectFieldPreview({super.key});

  @override
  ConsumerState<Md3eNamedFacetMultiSelectFieldPreview> createState() =>
      _Md3eNamedFacetMultiSelectFieldPreviewState();
}

class _Md3eNamedFacetMultiSelectFieldPreviewState
    extends ConsumerState<Md3eNamedFacetMultiSelectFieldPreview> {
  final List<String> _selected = <String>['已有作者'];

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Align(
        alignment: Alignment.topCenter,
        child: Md3eNamedFacetMultiSelectField<SmartFacetMatchCandidate>(
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
          itemsProvider: md3eNamedFacetMultiSelectPreviewProvider,
          onRetry: () =>
              ref.invalidate(md3eNamedFacetMultiSelectPreviewProvider),
          resolveName: (SmartFacetMatchCandidate c) => c.name,
          resolveSmartMatched: (SmartFacetMatchCandidate c) => c.smartMatched,
          smartMatchedTooltip: context.l10n.smartFacetMatchHintTooltip,
          copy: Md3eNamedFacetMultiSelectCopy(
            listLoadFailed: context.l10n.formAuthorListLoadFailed,
            emptyCatalog: context.l10n.formAuthorEmptyCatalog,
            emptyRemaining: context.l10n.formAuthorEmptyRemaining,
          ),
          maxWidth: 480,
        ),
      ),
    );
  }
}
