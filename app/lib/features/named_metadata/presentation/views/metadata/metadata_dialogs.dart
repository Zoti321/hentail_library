import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/lab_dialog_presenter.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/named_metadata/domain/tag_dictionary_import_result.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 合并确认：目标与来源列表摘要 + 「以后不再提示」。返回是否确认。
Future<bool> showMetadataMergeConfirmDialog({
  required BuildContext context,
  required String target,
  required int sourceCount,
  required ValueChanged<bool> onSkipChanged,
}) async {
  final bool? confirmed = await LabDialogPresenter.showBasic<bool>(
    context,
    dialog: _MergeConfirmDialog(
      target: target,
      sourceCount: sourceCount,
      onSkipChanged: onSkipChanged,
    ),
  );
  return confirmed ?? false;
}

class _MergeConfirmDialog extends StatefulWidget {
  const _MergeConfirmDialog({
    required this.target,
    required this.sourceCount,
    required this.onSkipChanged,
  });

  final String target;
  final int sourceCount;
  final ValueChanged<bool> onSkipChanged;

  @override
  State<_MergeConfirmDialog> createState() => _MergeConfirmDialogState();
}

class _MergeConfirmDialogState extends State<_MergeConfirmDialog> {
  bool _skip = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle actionLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );
    return M3EDialog(
      title: l10n.metadataMergeConfirmTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.metadataMergeConfirmBody(widget.sourceCount, widget.target),
            style: theme.typeScale.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _setSkip(!_skip),
            child: Row(
              children: <Widget>[
                M3ECheckbox(
                  value: _skip,
                  onChanged: (bool? v) => _setSkip(v ?? false),
                  focusable: true,
                ),
                Expanded(
                  child: Text(
                    l10n.metadataMergeConfirmDontAskAgain,
                    style: theme.typeScale.bodyMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
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
          label: Text(l10n.metadataMerge),
        ),
      ],
    );
  }

  void _setSkip(bool value) {
    setState(() => _skip = value);
    widget.onSkipChanged(value);
  }
}

/// 删除单个命名元数据（作者 / 标签 / 原作 / 角色）的确认。
Future<bool> showMetadataDeleteFacetDialog({
  required BuildContext context,
  required String name,
  required int attachmentCount,
}) async {
  final bool? confirmed = await LabDialogPresenter.showBasic<bool>(
    context,
    dialog: _DestructiveConfirmDialog(
      title: context.l10n.confirmDeleteNamedFacetTitle,
      message: context.l10n.confirmDeleteNamedFacetContent(
        name,
        attachmentCount,
      ),
    ),
  );
  return confirmed ?? false;
}

class _DestructiveConfirmDialog extends StatelessWidget {
  const _DestructiveConfirmDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle actionLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );
    return M3EDialog(
      title: title,
      content: Text(
        message,
        style: theme.typeScale.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
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
          decoration: M3EButtonDecoration.styleFrom(
            textStyle: actionLabelStyle,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          label: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}

/// 标签词典导入进度：下载或本地写入期间展示进度，完成后以结果关闭。
Future<TagDictionaryImportResult?> showMetadataTagDictionaryImportDialog({
  required BuildContext context,
  required VoidCallback onCancel,
  required String bodyText,
  required Future<TagDictionaryImportResult?> Function({
    void Function(int received, int total)? onDownloadProgress,
  })
  runImport,
}) {
  return LabDialogPresenter.showBasic<TagDictionaryImportResult>(
    context,
    barrierDismissible: false,
    dialog: _TagDictionaryImportDialog(
      onCancel: onCancel,
      bodyText: bodyText,
      runImport: runImport,
    ),
  );
}

class _TagDictionaryImportDialog extends StatefulWidget {
  const _TagDictionaryImportDialog({
    required this.onCancel,
    required this.bodyText,
    required this.runImport,
  });

  final VoidCallback onCancel;
  final String bodyText;
  final Future<TagDictionaryImportResult?> Function({
    void Function(int received, int total)? onDownloadProgress,
  })
  runImport;

  @override
  State<_TagDictionaryImportDialog> createState() =>
      _TagDictionaryImportDialogState();
}

class _TagDictionaryImportDialogState
    extends State<_TagDictionaryImportDialog> {
  double? _progress;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final TagDictionaryImportResult? result = await widget.runImport(
      onDownloadProgress: (int received, int total) {
        if (!mounted) {
          return;
        }
        setState(() => _progress = total <= 0 ? null : received / total);
      },
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle actionLabelStyle = labButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );
    return M3EDialog(
      title: l10n.metadataImportTagDictionaryDialogTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.bodyText,
            style: theme.typeScale.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          M3EProgressIndicator.linear(
            value: _progress,
            color: scheme.primary,
            trackColor: scheme.surfaceContainerHighest,
          ),
        ],
      ),
      bottomDivider: true,
      actions: <Widget>[
        M3EButton(
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
          style: M3EButtonStyle.text,
          decoration: M3EButtonDecoration(textStyle: actionLabelStyle),
          label: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}
