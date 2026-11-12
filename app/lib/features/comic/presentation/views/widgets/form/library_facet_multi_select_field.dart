import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/named_facet_multi_select_field.dart';
import 'package:hentai_library/features/named_metadata/public/named_metadata_form.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 全库 facet 多选（作者 / 角色 / 原作 / 标签）：字段内 chip + 内联输入。
///
/// [kind] 决定候选 provider 与失败/空态文案，其余外观完全一致。
class LibraryFacetMultiSelectField extends ConsumerWidget {
  const LibraryFacetMultiSelectField({
    super.key,
    required this.kind,
    required this.label,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    this.onClearAll,
    required this.scope,
  });

  final NamedFacetFormKind kind;
  final String label;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback? onClearAll;
  final ComicMetadataSmartFacetScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final provider = switch (kind) {
      NamedFacetFormKind.author => authorsSmartForComicMetadataFormProvider(
        scope,
      ),
      NamedFacetFormKind.character =>
        charactersSmartForComicMetadataFormProvider(scope),
      NamedFacetFormKind.parody => parodiesSmartForComicMetadataFormProvider(
        scope,
      ),
      NamedFacetFormKind.tag => tagsSmartForComicMetadataFormProvider(scope),
    };
    return NamedFacetMultiSelectField(
      label: label,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      onClearAll: onClearAll,
      itemsProvider: provider,
      onRetry: () => ref.invalidate(provider),
      copy: _copyFor(kind, l10n),
    );
  }

  static NamedFacetMultiSelectCopy _copyFor(
    NamedFacetFormKind kind,
    AppLocalizations l10n,
  ) {
    return switch (kind) {
      NamedFacetFormKind.author => NamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formAuthorListLoadFailed,
        emptyCatalog: l10n.formAuthorEmptyCatalog,
        emptyRemaining: l10n.formAuthorEmptyRemaining,
        retryLabel: l10n.commonRetry,
      ),
      NamedFacetFormKind.character => NamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formCharacterListLoadFailed,
        emptyCatalog: l10n.formCharacterEmptyCatalog,
        emptyRemaining: l10n.formCharacterEmptyRemaining,
        retryLabel: l10n.commonRetry,
      ),
      NamedFacetFormKind.parody => NamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formParodyListLoadFailed,
        emptyCatalog: l10n.formParodyEmptyCatalog,
        emptyRemaining: l10n.formParodyEmptyRemaining,
        retryLabel: l10n.commonRetry,
      ),
      NamedFacetFormKind.tag => NamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formTagListLoadFailed,
        emptyCatalog: l10n.formTagEmptyCatalog,
        emptyRemaining: l10n.formTagEmptyRemaining,
        retryLabel: l10n.commonRetry,
      ),
    };
  }
}
