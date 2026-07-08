import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double kMetadataPanelSubtitleFontSize = 13;

class MetadataPanelHeader extends StatelessWidget {
  const MetadataPanelHeader({
    required this.layoutTier,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.addEntityName,
    required this.onSearchChanged,
    required this.onAdd,
    super.key,
  });

  final MetadataLayoutTier layoutTier;
  final String title;
  final String subtitle;
  final String searchHint;
  final String addEntityName;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String shortcutLabel = _shortcutLabel(context);
    final String addButtonLabel = metadataAddButtonLabel(
      layoutTier,
      addEntityName,
      shortcutLabel,
    );
    final double titleFontSize = metadataPanelTitleFontSize(layoutTier);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double searchWidth = metadataSearchFieldWidth(
          layoutTier,
          constraints.maxWidth,
        );
        final Widget titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: cs.hentai.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: cs.hentai.textTertiary,
                fontSize: kMetadataPanelSubtitleFontSize,
              ),
            ),
          ],
        );
        final Widget searchField = SizedBox(
          width: searchWidth,
          child: CustomTextField(
            hintText: searchHint,
            onChanged: onSearchChanged,
          ),
        );
        final Widget addButton = FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: Text(addButtonLabel),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        if (metadataPanelHeaderIsVertical(layoutTier)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              titleSection,
              const SizedBox(height: 12),
              searchField,
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: addButton,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: titleSection),
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[searchField, addButton],
            ),
          ],
        );
      },
    );
  }
}

String _shortcutLabel(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;
  final bool isApple =
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  return isApple ? '⌘N' : 'Ctrl+N';
}
