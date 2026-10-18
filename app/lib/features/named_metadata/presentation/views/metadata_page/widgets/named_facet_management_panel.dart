import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/layout/page_content_width_layout.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/count_digit_chip.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/context_menu/named_facet_context_menu.dart';
import 'package:hentai_library/shared/di/author_detail_providers.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/author_management_notifier.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/tag_name_editor_dialog.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_controller.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'named_facet_management_states.dart';
part 'named_facet_list_widgets.dart';
part 'named_facet_merge_selection.dart';

class NamedFacetManagementSliverGroup extends ConsumerWidget {
  const NamedFacetManagementSliverGroup({
    required this.kind,
    required this.layoutTier,
    required this.viewportWidth,
    required this.horizontalPadding,
    required this.contentMaxWidth,
    this.mergeTarget,
    this.mergeSources = const <String>{},
    this.onMergeTargetSelected,
    this.onMergeSourceSelected,
    this.onMergeSelectionExited,
    super.key,
  });

  final ManagedNamedFacetKind kind;
  final MetadataLayoutTier layoutTier;
  final double viewportWidth;
  final double horizontalPadding;
  final double contentMaxWidth;
  final String? mergeTarget;
  final Set<String> mergeSources;
  final ValueChanged<String>? onMergeTargetSelected;
  final ValueChanged<String>? onMergeSourceSelected;
  final VoidCallback? onMergeSelectionExited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(namedFacetManagementControllerProvider(kind));
    final AppThemeTokens tokens = context.tokens;

    if (state.isLoading && state.items.isEmpty) {
      return _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _alignedListChild(
            context,
            const _NamedFacetManagementLoadingState(),
          ),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _alignedListChild(
            context,
            _NamedFacetManagementErrorState(
              error: state.error!,
              onRetry: () => ref
                  .read(namedFacetManagementControllerProvider(kind).notifier)
                  .refresh(),
            ),
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return _padListSliver(
        tokens,
        SliverToBoxAdapter(
          child: _alignedListChild(
            context,
            _NamedFacetManagementEmptyState(
              kind: kind,
              hasSearchQuery: state.hasSearchQuery,
              onCreate: () => openNamedFacetCreateDialog(context, ref, kind),
            ),
          ),
        ),
      );
    }

    return _padListSliver(
      tokens,
      SliverToBoxAdapter(
        child: _alignedListChild(
          context,
          _NamedFacetListSection(
            kind: kind,
            layoutTier: layoutTier,
            state: state,
            mergeTarget: mergeTarget,
            mergeSources: mergeSources,
            onMergeTargetSelected: onMergeTargetSelected,
            onMergeSourceSelected: onMergeSourceSelected,
            onMergeSelectionExited: onMergeSelectionExited,
          ),
        ),
      ),
    );
  }

  Widget _alignedListChild(BuildContext context, Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: pageContentAlignedHorizontalInset(
          viewportWidth: viewportWidth,
          horizontalPadding: horizontalPadding,
          maxWidth: contentMaxWidth,
        ),
      ),
      child: child,
    );
  }

  Widget _padListSliver(AppThemeTokens tokens, Widget sliver) {
    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: tokens.layout.contentVerticalPadding + 24,
      ),
      sliver: sliver,
    );
  }
}

/// Flat Fluent list section: no card shell — spacing + hairline only.
