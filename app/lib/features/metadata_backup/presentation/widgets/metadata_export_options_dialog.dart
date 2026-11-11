import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 导出选项：M3E dialog + gzip / 孤立项开关。
Future<MetadataExportOptions?> showMetadataExportOptionsDialog({
  required BuildContext context,
  required MetadataExportOptions initialOptions,
}) {
  return LabDialogPresenter.showBasic<MetadataExportOptions>(
    context,
    dialog: MetadataExportOptionsDialog(initialOptions: initialOptions),
  );
}

class MetadataExportOptionsDialog extends StatefulWidget {
  const MetadataExportOptionsDialog({required this.initialOptions, super.key});

  final MetadataExportOptions initialOptions;

  @override
  State<MetadataExportOptionsDialog> createState() =>
      _MetadataExportOptionsDialogState();
}

class _MetadataExportOptionsDialogState
    extends State<MetadataExportOptionsDialog> {
  late bool _gzip;
  late bool _includeOrphanFacets;

  @override
  void initState() {
    super.initState();
    _gzip = widget.initialOptions.gzip;
    _includeOrphanFacets = widget.initialOptions.includeOrphanFacets;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ESpacing spacing = theme.spacing;
    final TextStyle actionLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );

    return M3EDialog(
      title: l10n.settingsMetadataBackupExportDialogTitle,
      subhead: l10n.settingsMetadataBackupExportDescription,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ExportSwitchRow(
            title: l10n.settingsMetadataBackupExportGzipLabel,
            value: _gzip,
            onChanged: (bool value) => setState(() => _gzip = value),
            onLabel: l10n.commonToggleOn,
            offLabel: l10n.commonToggleOff,
            scheme: scheme,
            spacing: spacing,
            theme: theme,
          ),
          SizedBox(height: spacing.lg),
          _ExportSwitchRow(
            title: l10n.settingsMetadataBackupExportOrphanFacetsLabel,
            value: _includeOrphanFacets,
            onChanged: (bool value) =>
                setState(() => _includeOrphanFacets = value),
            onLabel: l10n.commonToggleOn,
            offLabel: l10n.commonToggleOff,
            scheme: scheme,
            spacing: spacing,
            theme: theme,
          ),
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: () => Navigator.of(context).pop(
            MetadataExportOptions(
              gzip: _gzip,
              includeOrphanFacets: _includeOrphanFacets,
              libraryId: widget.initialOptions.libraryId,
            ),
          ),
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.settingsMetadataBackupExportConfirm),
        ),
      ],
    );
  }
}

class _ExportSwitchRow extends StatelessWidget {
  const _ExportSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onLabel,
    required this.offLabel,
    required this.scheme,
    required this.spacing,
    required this.theme,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String onLabel;
  final String offLabel;
  final M3EColorScheme scheme;
  final M3ESpacing spacing;
  final M3EThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.xs),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.typeScale.bodyLarge.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    value ? onLabel : offLabel,
                    style: theme.typeScale.bodyMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.md),
            M3ESwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
