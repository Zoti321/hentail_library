import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_toggle_field.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/hentai_dialog.dart';

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
    final AppThemeTokens tokens = context.tokens;

    return HentaiDialog(
      title: l10n.settingsMetadataBackupExportDialogTitle,
      fitContentHeight: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.settingsMetadataBackupExportDescription,
            style: TextStyle(
              fontSize: tokens.text.bodyMd,
              color: context.hentai.textSecondary,
              height: 1.45,
            ),
          ),
          SizedBox(height: tokens.spacing.lg),
          FluentToggleField(
            labelText: l10n.settingsMetadataBackupExportGzipLabel,
            value: _gzip,
            checkedLabel: l10n.commonToggleOn,
            uncheckedLabel: l10n.commonToggleOff,
            onChanged: (bool value) => setState(() => _gzip = value),
          ),
          SizedBox(height: tokens.spacing.lg),
          FluentToggleField(
            labelText: l10n.settingsMetadataBackupExportOrphanFacetsLabel,
            value: _includeOrphanFacets,
            checkedLabel: l10n.commonToggleOn,
            uncheckedLabel: l10n.commonToggleOff,
            onChanged: (bool value) =>
                setState(() => _includeOrphanFacets = value),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            MetadataExportOptions(
              gzip: _gzip,
              includeOrphanFacets: _includeOrphanFacets,
              libraryId: widget.initialOptions.libraryId,
            ),
          ),
          child: Text(l10n.settingsMetadataBackupExportConfirm),
        ),
      ],
    );
  }
}
