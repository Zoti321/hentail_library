import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/patterns/dialog/md3e_lab_dialog_presenter.dart';
import 'package:hentai_library/md3e/theme/md3e_lab_text.dart';
import 'package:hentai_library/shared/domain/models/tag_dictionary_import_result.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 合并确认：目标与来源列表摘要 + 「以后不再提示」。返回是否确认。
Future<bool> showMetadataMd3eMergeConfirmDialog({
  required BuildContext context,
  required String target,
  required int sourceCount,
  required ValueChanged<bool> onSkipChanged,
}) async {
  final bool? confirmed = await Md3eLabDialogPresenter.showBasic<bool>(
    context,
    dialog: _Md3eMergeConfirmDialog(
      target: target,
      sourceCount: sourceCount,
      onSkipChanged: onSkipChanged,
    ),
  );
  return confirmed ?? false;
}

class _Md3eMergeConfirmDialog extends StatefulWidget {
  const _Md3eMergeConfirmDialog({
    required this.target,
    required this.sourceCount,
    required this.onSkipChanged,
  });

  final String target;
  final int sourceCount;
  final ValueChanged<bool> onSkipChanged;

  @override
  State<_Md3eMergeConfirmDialog> createState() =>
      _Md3eMergeConfirmDialogState();
}

class _Md3eMergeConfirmDialogState extends State<_Md3eMergeConfirmDialog> {
  bool _skip = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle actionLabelStyle = md3eLabButtonLabelStyle(
      theme,
      M3EButtonSize.sm,
    );
    return M3EDialog(
      title: '确认合并',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '将 ${widget.sourceCount} 个 tag 合并到「${widget.target}」？源 tag 的 Comic 附着会转移到目标，源 tag 将被删除。',
            style: theme.typeScale.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _setSkip(!_skip),
            child: Row(
              children: <Widget>[
                Checkbox(
                  value: _skip,
                  onChanged: (bool? v) => _setSkip(v ?? false),
                ),
                Expanded(
                  child: Text(
                    '以后不再提示',
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

/// 删除全部标签的危险确认（无勾选闸门，沿用 Baseline 语义）。
Future<bool> showMetadataMd3eDeleteAllTagsDialog({
  required BuildContext context,
  required int count,
}) async {
  final bool? confirmed = await Md3eLabDialogPresenter.showBasic<bool>(
    context,
    dialog: _Md3eDestructiveConfirmDialog(
      title: context.l10n.confirmDeleteTagsTitle,
      message: context.l10n.confirmDeleteTagsContent(count),
    ),
  );
  return confirmed ?? false;
}

/// 删除单个命名元数据（作者 / 标签 / 原作 / 角色）的确认。
Future<bool> showMetadataMd3eDeleteFacetDialog({
  required BuildContext context,
  required String name,
  required int attachmentCount,
}) async {
  final bool? confirmed = await Md3eLabDialogPresenter.showBasic<bool>(
    context,
    dialog: _Md3eDestructiveConfirmDialog(
      title: context.l10n.confirmDeleteNamedFacetTitle,
      message: context.l10n.confirmDeleteNamedFacetContent(
        name,
        attachmentCount,
      ),
    ),
  );
  return confirmed ?? false;
}

class _Md3eDestructiveConfirmDialog extends StatelessWidget {
  const _Md3eDestructiveConfirmDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final TextStyle actionLabelStyle = md3eLabButtonLabelStyle(
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

/// 标签词典导入进度：下载期间展示进度，完成后以结果关闭。
Future<TagDictionaryImportResult?> showMetadataMd3eTagDictionaryImportDialog({
  required BuildContext context,
  required VoidCallback onCancel,
  required Future<TagDictionaryImportResult?> Function({
    void Function(int received, int total)? onDownloadProgress,
  })
  importFromNetwork,
}) {
  return Md3eLabDialogPresenter.showBasic<TagDictionaryImportResult>(
    context,
    barrierDismissible: false,
    dialog: _Md3eTagDictionaryImportDialog(
      onCancel: onCancel,
      importFromNetwork: importFromNetwork,
    ),
  );
}

class _Md3eTagDictionaryImportDialog extends StatefulWidget {
  const _Md3eTagDictionaryImportDialog({
    required this.onCancel,
    required this.importFromNetwork,
  });

  final VoidCallback onCancel;
  final Future<TagDictionaryImportResult?> Function({
    void Function(int received, int total)? onDownloadProgress,
  })
  importFromNetwork;

  @override
  State<_Md3eTagDictionaryImportDialog> createState() =>
      _Md3eTagDictionaryImportDialogState();
}

class _Md3eTagDictionaryImportDialogState
    extends State<_Md3eTagDictionaryImportDialog> {
  double? _progress;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final TagDictionaryImportResult? result = await widget.importFromNetwork(
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
    final TextStyle actionLabelStyle = md3eLabButtonLabelStyle(
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
            l10n.metadataImportTagDictionaryDialogBody,
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
