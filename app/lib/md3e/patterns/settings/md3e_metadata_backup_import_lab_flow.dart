import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/md3e/theme/md3e_lab_text.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 元数据备份导入预演数据（只读示例，不读文件、不写库）。
class Md3eMetadataBackupImportLabPreview {
  const Md3eMetadataBackupImportLabPreview({
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

const Md3eMetadataBackupImportLabPreview kMd3eMetadataBackupImportLabPreview =
    Md3eMetadataBackupImportLabPreview(
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
Future<void> showMd3eMetadataBackupImportLabFlow(BuildContext context) async {
  final bool picked = await _showPickDialog(context);
  if (!picked || !context.mounted) {
    return;
  }
  final bool confirmed = await _showConfirmDialog(
    context,
    kMd3eMetadataBackupImportLabPreview,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  await _showResultDialog(context, kMd3eMetadataBackupImportLabPreview);
}

Future<bool> _showPickDialog(BuildContext context) async {
  final bool? result = await Md3eLabDialogPresenter.showBasic<bool>(
    context,
    dialog: const _Md3eMetadataImportPickDialog(),
  );
  return result ?? false;
}

Future<bool> _showConfirmDialog(
  BuildContext context,
  Md3eMetadataBackupImportLabPreview preview,
) async {
  final bool? result = await Md3eLabDialogPresenter.showBasic<bool>(
    context,
    dialog: _Md3eMetadataImportConfirmDialog(preview: preview),
  );
  return result ?? false;
}

Future<void> _showResultDialog(
  BuildContext context,
  Md3eMetadataBackupImportLabPreview preview,
) {
  return Md3eLabDialogPresenter.showBasic<void>(
    context,
    dialog: _Md3eMetadataImportResultDialog(preview: preview),
  );
}

class _Md3eMetadataImportPickDialog extends StatelessWidget {
  const _Md3eMetadataImportPickDialog();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle actionLabelStyle = md3eLabButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );

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
        M3EButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}

class _Md3eMetadataImportConfirmDialog extends StatelessWidget {
  const _Md3eMetadataImportConfirmDialog({required this.preview});

  final Md3eMetadataBackupImportLabPreview preview;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle actionLabelStyle = md3eLabButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );

    return M3EDialog(
      title: l10n.settingsMetadataBackupImportConfirmTitle,
      content: _Md3eImportSummaryColumn(
        sections: <_Md3eImportSummarySection>[
          _Md3eImportSummarySection(
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
          _Md3eImportSummarySection(
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
          _Md3eImportSummarySection(
            title: null,
            rows: const <(String, String)>[],
            footnote: l10n.settingsMetadataBackupImportConfirmWarning,
          ),
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonCancel),
        ),
        M3EButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: M3EButtonStyle.filled,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(
            l10n.settingsMetadataBackupImportConfirmActionWithCount(
              preview.wouldApply,
            ),
          ),
        ),
      ],
    );
  }
}

class _Md3eMetadataImportResultDialog extends StatelessWidget {
  const _Md3eMetadataImportResultDialog({required this.preview});

  final Md3eMetadataBackupImportLabPreview preview;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final TextStyle actionLabelStyle = md3eLabButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );

    return M3EDialog(
      title: l10n.settingsMetadataBackupImportResultTitle,
      content: _Md3eImportSummaryColumn(
        sections: <_Md3eImportSummarySection>[
          _Md3eImportSummarySection(
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
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

class _Md3eImportSummarySection {
  const _Md3eImportSummarySection({
    required this.title,
    required this.rows,
    this.footnote,
  });

  final String? title;
  final List<(String, String)> rows;
  final String? footnote;
}

class _Md3eImportSummaryColumn extends StatelessWidget {
  const _Md3eImportSummaryColumn({required this.sections});

  final List<_Md3eImportSummarySection> sections;

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
        for (final _Md3eImportSummarySection section in sections) ...<Widget>[
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
