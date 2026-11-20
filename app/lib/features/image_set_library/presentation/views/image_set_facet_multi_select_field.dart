import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_named_facet_kind.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_facet_dictionary_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';

/// Image set 元数据编辑：facet 多选（字典由 image_set_library owner 提供）。
class ImageSetFacetMultiSelectField extends ConsumerWidget {
  const ImageSetFacetMultiSelectField({
    super.key,
    required this.kind,
    required this.label,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    this.onClearAll,
  });

  final ImageSetNamedFacetKind kind;
  final String label;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<String>> namesAsync = ref.watch(
      imageSetFacetDictionaryProvider(kind),
    );
    final ({
      List<String> items,
      bool loading,
      bool error,
    }) candidates = namesAsync.when(
      data: (List<String> items) => (items: items, loading: false, error: false),
      loading: () => (items: const <String>[], loading: true, error: false),
      error: (_, _) => (items: const <String>[], loading: false, error: true),
    );

    return FacetMultiSelectField<String>(
      label: label,
      selectedNames: selectedNames,
      onAdd: onAdd,
      onRemove: onRemove,
      onClearAll: onClearAll,
      items: candidates.items,
      isLoading: candidates.loading,
      hasLoadError: candidates.error,
      onRetry: () => ref.invalidate(imageSetFacetDictionaryProvider(kind)),
      resolveName: (String name) => name,
      resolveSmartMatched: (_) => false,
      copy: _copyFor(kind, l10n),
      maxWidth: double.infinity,
    );
  }

  static NamedFacetMultiSelectCopy _copyFor(
    ImageSetNamedFacetKind kind,
    AppLocalizations l10n,
  ) {
    return switch (kind) {
      ImageSetNamedFacetKind.author => NamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formAuthorListLoadFailed,
        emptyCatalog: l10n.formAuthorEmptyCatalog,
        emptyRemaining: l10n.formAuthorEmptyRemaining,
        retryLabel: l10n.commonRetry,
      ),
      ImageSetNamedFacetKind.character => NamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formCharacterListLoadFailed,
        emptyCatalog: l10n.formCharacterEmptyCatalog,
        emptyRemaining: l10n.formCharacterEmptyRemaining,
        retryLabel: l10n.commonRetry,
      ),
      ImageSetNamedFacetKind.parody => NamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formParodyListLoadFailed,
        emptyCatalog: l10n.formParodyEmptyCatalog,
        emptyRemaining: l10n.formParodyEmptyRemaining,
        retryLabel: l10n.commonRetry,
      ),
      ImageSetNamedFacetKind.tag => NamedFacetMultiSelectCopy(
        listLoadFailed: l10n.formTagListLoadFailed,
        emptyCatalog: l10n.formTagEmptyCatalog,
        emptyRemaining: l10n.formTagEmptyRemaining,
        retryLabel: l10n.commonRetry,
      ),
    };
  }
}