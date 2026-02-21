import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/presentation/widgets/form/content_rating_field.dart';
import 'package:hentai_library/presentation/widgets/form/date_picker_field.dart';
import 'package:hentai_library/presentation/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/presentation/widgets/form/tag_edit_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditMetadataDialog extends StatefulHookConsumerWidget {
  const EditMetadataDialog({
    super.key,
    required this.comic,
    required this.onSave,
  });

  final Comic comic;
  final Future<void> Function(ComicMetadataForm) onSave;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditMetadataDialogState();
}

class _EditMetadataDialogState extends ConsumerState<EditMetadataDialog> {
  late ComicMetadataForm _formData;
  String activeTab = 'details';
  bool _saving = false;

  bool get _isR18 => _formData.tags.any((e) => e.isR18) || _formData.isR18;

  @override
  void initState() {
    super.initState();
    _formData = ComicMetadataForm(
      title: widget.comic.title,
      firstPublishedAt: widget.comic.firstPublishedAt,
      isR18: widget.comic.isR18,
      description: widget.comic.description,
      tags: widget.comic.tags,
    );
  }

  void _handleTagAdd(CategoryTag tag) {
    if (tag.name.isEmpty) return;
    if (!_formData.tags.contains(tag)) {
      setState(() {
        _formData = _formData.copyWith(tags: [..._formData.tags, tag]);
      });
    }
  }

  void _handleTagRemove(CategoryTag tag) {
    setState(() {
      _formData = _formData.copyWith(tags: [..._formData.tags]..remove(tag));
    });
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_formData);
      if (mounted) {
        showSuccessSnackBar(context, '已保存');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e is AppException ? e : e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 680,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.cardHover,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.borderSubtle,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                _DialogHeader(borderSubtle: theme.colorScheme.borderSubtle),

                // Tabs 标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    spacing: 24,
                    children: [
                      _TabButton(
                        label: "常规信息",
                        isActive: activeTab == 'details',
                        onTap: () => setState(() => activeTab = 'details'),
                        primaryColor: theme.colorScheme.primary,
                      ),
                      _TabButton(
                        label: "分类标签",
                        isActive: activeTab == 'tags',
                        onTap: () => setState(() => activeTab = 'tags'),
                        primaryColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                // 对话框 body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: activeTab == 'details'
                        ? _buildDetailsTab(theme.colorScheme.primary)
                        : _buildTagsTab(),
                  ),
                ),

                _DialogFooter(
                  borderSubtle: theme.colorScheme.borderSubtle,
                  primaryColor: theme.colorScheme.primary,
                  saving: _saving,
                  onSave: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(Color primaryColor) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 20,

      children: [
        FluentTextField(
          labelText: "漫画标题",
          initialValue: _formData.title,
          onChanged: (v) => _formData = _formData.copyWith(title: v),
          hintText: '修改漫画标题',
        ),
        Row(
          crossAxisAlignment: .start,
          spacing: 20,
          children: [
            Expanded(
              child: FluentDatePicker(
                labelText: "第一次发布日期",
                hintText: "选择日期",
                initialDate: _formData.firstPublishedAt,
                onChanged: (date) =>
                    _formData = _formData.copyWith(firstPublishedAt: date),
              ),
            ),
            // 内容分级字段
            Expanded(
              child: ContentRatingField(
                isR18: _isR18,
                onChanged: (value) {
                  _formData = _formData.copyWith(isR18: value);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        FluentTextField(
          labelText: "简介",
          initialValue: _formData.description,
          maxLines: 6,
          onChanged: (v) => _formData = _formData.copyWith(description: v),
          hintText: '输入简介',
        ),
      ],
    );
  }

  Widget _buildTagsTab() {
    return Column(
      crossAxisAlignment: .start,
      children: [
        TagEditorField(
          label: "作者",
          icon: LucideIcons.penTool,
          tags: _formData.tags
              .where((e) => e.type == CategoryTagType.author)
              .toList(),
          onAdd: (t) => _handleTagAdd(t),
          onRemove: (t) => _handleTagRemove(t),
          tagType: CategoryTagType.author,
        ),
        const SizedBox(height: 20),
        TagEditorField(
          label: "登场人物",
          icon: LucideIcons.users,
          tags: _formData.tags
              .where((e) => e.type == CategoryTagType.character)
              .toList(),
          onAdd: (t) => _handleTagAdd(t),
          onRemove: (t) => _handleTagRemove(t),
          tagType: CategoryTagType.character,
        ),
        const SizedBox(height: 20),
        TagEditorField(
          label: "系列",
          icon: LucideIcons.library,
          tags: _formData.tags
              .where((e) => e.type == CategoryTagType.series)
              .toList(),
          onAdd: (t) => _handleTagAdd(t),
          onRemove: (t) => _handleTagRemove(t),
          tagType: CategoryTagType.series,
        ),
        const SizedBox(height: 20),
        TagEditorField(
          label: "通用标签",
          icon: LucideIcons.tag,
          tags: _formData.tags
              .where((e) => e.type == CategoryTagType.tag)
              .toList(),
          onAdd: (t) => _handleTagAdd(t),
          onRemove: (t) => _handleTagRemove(t),
          tagType: CategoryTagType.tag,
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color primaryColor;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      splashColor: primaryColor.withAlpha(20),
      highlightColor: primaryColor.withAlpha(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? primaryColor : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? primaryColor : colorScheme.textTertiary,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.borderSubtle});

  final Color borderSubtle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderSubtle, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(
            "编辑元数据",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.x,
                  size: 20,
                  color: colorScheme.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    required this.borderSubtle,
    required this.primaryColor,
    required this.saving,
    required this.onSave,
  });

  final Color borderSubtle;
  final Color primaryColor;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderSubtle, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: .end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text("取消"),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: saving
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('保存中…'),
                    ],
                  )
                : const Text("保存更改"),
          ),
        ],
      ),
    );
  }
}
