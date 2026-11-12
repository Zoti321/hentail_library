import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 元数据备份导入预演数据（只读示例，不读文件、不写库）。
class MetadataBackupImportLabPreview {
  const MetadataBackupImportLabPreview({
    required this.schemaVersion,
    required this.exportedAt,
    required this.comicCount,
    required this.appVersion,
    required this.wouldApply,
    required this.skippedNotFound,
    required this.skippedAmbiguous,
    required this.orphanFacets,
  });

  final int schemaVersion;
  final String exportedAt;
  final int comicCount;
  final String appVersion;

  /// 匹配预演：将恢复的 Comic 数。
  final int wouldApply;
  final int skippedNotFound;
  final int skippedAmbiguous;
  final int orphanFacets;
}

const MetadataBackupImportLabPreview kMetadataBackupImportLabPreview =
    MetadataBackupImportLabPreview(
      schemaVersion: 3,
      exportedAt: '2026-06-15 14:00',
      comicCount: 15,
      appVersion: '0.0.0-lab',
      wouldApply: 12,
      skippedNotFound: 2,
      skippedAmbiguous: 1,
      orphanFacets: 2,
    );

/// Lab：元数据备份导入「选择 → 确认 → 结果」三步弹窗，全部为内存预演。
Future<void> showMetadataBackupImportLabFlow(BuildContext context) async {
  final bool picked = await _showPickDialog(context);
  if (!picked || !context.mounted) {
    return;
  }
  final bool confirmed = await _showConfirmDialog(
    context,
    kMetadataBackupImportLabPreview,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  await _showResultDialog(context, kMetadataBackupImportLabPreview);
}

Future<bool> _showPickDialog(BuildContext context) async {
  final bool? result = await LabDialogPresenter.showBasic<bool>(
    context,
    dialog: const _MetadataImportPickDialog(),
  );
  return result ?? false;
}

Future<bool> _showConfirmDialog(
  BuildContext context,
  MetadataBackupImportLabPreview preview,
) async {
  final bool? result = await LabDialogPresenter.showBasic<bool>(
    context,
    dialog: _MetadataImportConfirmPanel(preview: preview),
  );
  return result ?? false;
}

Future<void> _showResultDialog(
  BuildContext context,
  MetadataBackupImportLabPreview preview,
) {
  return LabDialogPresenter.showBasic<void>(
    context,
    dialog: _MetadataImportResultPanel(preview: preview),
  );
}

class _MetadataImportPickDialog extends StatelessWidget {
  const _MetadataImportPickDialog();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);

    return M3EDialog(
      title: l10n.settingsMetadataBackupImportPickDialogTitle,
      content: Text(
        'hentai-library-backup.hlmeta.json',
        style: theme.typeScale.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      bottomDivider: true,
      actions: <Widget>[
        DialogActionBar(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          cancelLabel: l10n.commonCancel,
          confirmLabel: l10n.commonConfirm,
        ),
      ],
    );
  }
}

class _MetadataImportConfirmPanel extends StatelessWidget {
  const _MetadataImportConfirmPanel({required this.preview});

  final MetadataBackupImportLabPreview preview;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return M3EDialog(
      title: l10n.settingsMetadataBackupImportConfirmTitle,
      content: _ImportSummaryColumn(
        sections: <_ImportSummarySection>[
          _ImportSummarySection(
            title: l10n.settingsMetadataBackupImportConfirmManifestSection,
            rows: <(String, String)>[
              (
                l10n.settingsMetadataBackupImportManifestSchema,
                '${preview.schemaVersion}',
              ),
              (
                l10n.settingsMetadataBackupImportManifestExportedAt,
                preview.exportedAt,
              ),
              (
                l10n.settingsMetadataBackupImportManifestComicCount,
                '${preview.comicCount}',
              ),
              (
                l10n.settingsMetadataBackupImportManifestAppVersion,
                preview.appVersion,
              ),
            ],
          ),
          _ImportSummarySection(
            title: l10n.settingsMetadataBackupImportConfirmPreviewSection,
            rows: <(String, String)>[
              (
                l10n.settingsMetadataBackupImportPreviewWouldApply,
                '${preview.wouldApply}',
              ),
              (
                l10n.settingsMetadataBackupImportPreviewSkippedNotFound,
                '${preview.skippedNotFound}',
              ),
              (
                l10n.settingsMetadataBackupImportPreviewSkippedAmbiguous,
                '${preview.skippedAmbiguous}',
              ),
              (
                l10n.settingsMetadataBackupImportPreviewOrphanFacets,
                '${preview.orphanFacets}',
              ),
            ],
          ),
          _ImportSummarySection(
            title: null,
            rows: const <(String, String)>[],
            footnote: l10n.settingsMetadataBackupImportConfirmWarning,
          ),
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        DialogActionBar(
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          cancelLabel: l10n.commonCancel,
          confirmLabel: l10n.settingsMetadataBackupImportConfirmActionWithCount(
            preview.wouldApply,
          ),
        ),
      ],
    );
  }
}

class _MetadataImportResultPanel extends StatelessWidget {
  const _MetadataImportResultPanel({required this.preview});

  final MetadataBackupImportLabPreview preview;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);

    return M3EDialog(
      title: l10n.settingsMetadataBackupImportResultTitle,
      content: _ImportSummaryColumn(
        sections: <_ImportSummarySection>[
          _ImportSummarySection(
            title: null,
            rows: <(String, String)>[
              (
                l10n.settingsMetadataBackupImportResultApplied,
                '${preview.wouldApply}',
              ),
              (
                l10n.settingsMetadataBackupImportResultSkippedNotFound,
                '${preview.skippedNotFound}',
              ),
              (
                l10n.settingsMetadataBackupImportResultSkippedAmbiguous,
                '${preview.skippedAmbiguous}',
              ),
              (l10n.settingsMetadataBackupImportResultErrors, '0'),
            ],
          ),
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration(
            textStyle: labButtonLabelStyle(theme, M3EButtonSize.sm),
          ),
          label: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

class _ImportSummarySection {
  const _ImportSummarySection({
    required this.title,
    required this.rows,
    this.footnote,
  });

  final String? title;
  final List<(String, String)> rows;
  final String? footnote;
}

class _ImportSummaryColumn extends StatelessWidget {
  const _ImportSummaryColumn({required this.sections});

  final List<_ImportSummarySection> sections;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle bodyStyle = theme.typeScale.bodyMedium.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final _ImportSummarySection section in sections) ...<Widget>[
          if (section.title != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                section.title!,
                style: theme.typeScale.titleSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          for (final (String label, String value) in section.rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(label, style: bodyStyle)),
                  Text(value, style: bodyStyle),
                ],
              ),
            ),
          if (section.footnote != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(section.footnote!, style: bodyStyle),
            ),
        ],
      ],
    );
  }
}
