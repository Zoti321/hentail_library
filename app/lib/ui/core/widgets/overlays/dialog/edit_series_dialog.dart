import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditSeriesDialog extends ConsumerStatefulWidget {
  const EditSeriesDialog({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<EditSeriesDialog> createState() => _EditSeriesDialogState();
}

class _EditSeriesDialogState extends ConsumerState<EditSeriesDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _totalCountController;
  late SerializationStatus _serializationStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.series.name);
    _totalCountController = TextEditingController(
      text: widget.series.totalCount?.toString() ?? '',
    );
    _serializationStatus = widget.series.serializationStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalCountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) {
      return;
    }
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      showInfoToast(context, '系列名称不能为空');
      return;
    }
    final String rawTotal = _totalCountController.text.trim();
    int? totalCount;
    var clearTotalCount = false;
    if (rawTotal.isEmpty) {
      clearTotalCount = widget.series.totalCount != null;
    } else {
      totalCount = int.tryParse(rawTotal);
      if (totalCount == null || totalCount <= 0) {
        showInfoToast(context, '漫画总数须为正整数，留空表示不设置');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(seriesRepoProvider)
          .updateUserMeta(
            seriesId: widget.series.id,
            name: name,
            serializationStatus: _serializationStatus,
            totalCount: totalCount,
            clearTotalCount: clearTotalCount,
          );
      if (mounted) {
        showSuccessToast(context, '系列信息已保存');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showErrorToast(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return HentaiDialog(
      title: '编辑系列',
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spacing.md,
        children: <Widget>[
          TextField(
            controller: _nameController,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: '系列名称',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          DropdownButtonFormField<SerializationStatus>(
            value: _serializationStatus,
            decoration: const InputDecoration(
              labelText: '连载状态',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: SerializationStatus.values
                .map(
                  (SerializationStatus status) =>
                      DropdownMenuItem<SerializationStatus>(
                        value: status,
                        child: Text(status.label),
                      ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (SerializationStatus? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _serializationStatus = value);
                  },
          ),
          TextField(
            controller: _totalCountController,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '漫画总数',
              hintText: '留空表示不设置',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
