import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';
import 'package:hentai_library/ui/features/metadata/view_models/named_facet_management_controller.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_page_header.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';

class MetadataContentSearch extends ConsumerWidget {
  const MetadataContentSearch({
    required this.layoutTier,
    required this.selectedTabIndex,
    required this.contentMaxWidth,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final int selectedTabIndex;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final String hintText = context.l10n.metadataSearchNameHint;
    final ManagedNamedFacetKind kind = metadataTabKind(selectedTabIndex);
    final String query = ref
        .watch(namedFacetManagementControllerProvider(kind))
        .query;

    return Padding(
      padding: EdgeInsets.only(
        top: tokens.layout.contentVerticalPadding,
        bottom: kMetadataSearchToListSpacing,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: metadataSearchFieldWidth(layoutTier, contentMaxWidth),
          ),
          child: _MetadataSearchField(
            key: ValueKey<int>(selectedTabIndex),
            hintText: hintText,
            initialQuery: query,
            onChanged: (String value) {
              ref
                  .read(namedFacetManagementControllerProvider(kind).notifier)
                  .setQuery(value);
            },
          ),
        ),
      ),
    );
  }
}

class _MetadataSearchField extends StatefulWidget {
  const _MetadataSearchField({
    required this.hintText,
    required this.initialQuery,
    required this.onChanged,
    super.key,
  });

  final String hintText;
  final String initialQuery;
  final ValueChanged<String> onChanged;

  @override
  State<_MetadataSearchField> createState() => _MetadataSearchFieldState();
}

class _MetadataSearchFieldState extends State<_MetadataSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: _controller,
      hintText: widget.hintText,
      onChanged: widget.onChanged,
    );
  }
}
