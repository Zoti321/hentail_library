import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_date_picker_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/ui/core/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/dialog_side_tab_bar.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 漫画元数据编辑弹窗。
///
/// 当前：最大宽度 720px，随 viewport 收缩；左侧 tab + 右侧可滚动表单。
/// TODO(响应式): 窄屏下改为全页编辑（参考 Komga `EditBooksDialog` 小屏 fullscreen），见 `docs/agents/ui-style.md`。
const double _kEditMetadataDialogWidth = 720;
const double _kEditMetadataDialogRadius = 4;

/// [HentaiDialog] 标题区与底栏的近似高度，用于限制 body 最大滚动区。
const double _kEditMetadataShellChromeReserve = 120;

const double _kEditMetadataBodyMinHeight = 240;

enum _EditMetadataTab { general, authorsAndTags }

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
  late final _EditMetadataFormController _controller;
  _EditMetadataTab _selectedTab = _EditMetadataTab.general;
  bool _saving = false;

  static final List<DialogSideTabItem> _sideTabs = <DialogSideTabItem>[
    DialogSideTabItem(label: '常规', icon: LucideIcons.textAlignCenter),
    DialogSideTabItem(label: '作者&标签', icon: LucideIcons.users),
  ];

  @override
  void initState() {
    super.initState();
    final ComicMetadataForm initialForm = ComicMetadataForm(
      title: widget.comic.title,
      description: widget.comic.description,
      publishedAt: widget.comic.publishedAt,
      isR18: widget.comic.contentRating == ContentRating.r18,
      tags: List<Tag>.from(widget.comic.tags),
      authors: List<Author>.from(widget.comic.authors),
    );
    _controller = _EditMetadataFormController(initialForm: initialForm)
      ..addListener(_handleFormChanged);
  }

  void _handleFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleFormChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_controller.markTitleValidationAttempted()) {
      setState(() => _selectedTab = _EditMetadataTab.general);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.normalizedForm);
      if (mounted) {
        showSuccessToast(context, '已保存');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final int selectedTabIndex = _selectedTab.index;

    return HentaiDialog(
      title: '编辑元数据',
      width: _kEditMetadataDialogWidth,
      borderRadius: _kEditMetadataDialogRadius,
      scrollableContent: false,
      contentPadding: EdgeInsets.zero,
      backgroundColor: cs.surface,
      showFooterDivider: false,
      fitContentHeight: true,
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: _kEditMetadataBodyMinHeight,
          maxHeight: math.max(
            _kEditMetadataBodyMinHeight,
            MediaQuery.sizeOf(context).height * 0.88 -
                _kEditMetadataShellChromeReserve,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DialogSideTabBar(
              items: _sideTabs,
              selectedIndex: selectedTabIndex,
              showDivider: false,
              onSelected: (int index) {
                setState(() => _selectedTab = _EditMetadataTab.values[index]);
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.lg,
                  0,
                  18,
                  tokens.spacing.xs,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: switch (_selectedTab) {
                    _EditMetadataTab.general => _EditMetadataGeneralTab(
                      key: const ValueKey<String>('general'),
                      title: _controller.form.title,
                      titleError: _controller.titleErrorText,
                      description: _controller.form.description ?? '',
                      publishedAt: _controller.form.publishedAt,
                      isR18: _controller.form.isR18,
                      onTitleChanged: _controller.updateTitle,
                      onDescriptionChanged: _controller.updateDescription,
                      onPublishedAtChanged: _controller.updatePublishedAt,
                      onIsR18Changed: _controller.updateIsR18,
                    ),
                    _EditMetadataTab.authorsAndTags =>
                      _EditMetadataAuthorsTagsTab(
                        key: const ValueKey<String>('authors-tags'),
                        authors: _controller.form.authors,
                        tags: _controller.form.tags,
                        onAddAuthor: _controller.addAuthor,
                        onRemoveAuthor: _controller.removeAuthor,
                        onAddTag: _controller.addTagByName,
                        onRemoveTag: _controller.removeTagByName,
                      ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kEditMetadataDialogRadius),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kEditMetadataDialogRadius),
            ),
          ),
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary,
                  ),
                )
              : const Text('保存更改'),
        ),
      ],
    );
  }
}

class _EditMetadataFormController extends ChangeNotifier {
  _EditMetadataFormController({required ComicMetadataForm initialForm})
    : _form = initialForm;

  ComicMetadataForm _form;
  bool _titleValidationAttempted = false;

  ComicMetadataForm get form => _form;

  String? get titleErrorText {
    if (!_titleValidationAttempted) {
      return null;
    }
    return _form.title.trim().isEmpty ? '漫画标题不能为空' : null;
  }

  ComicMetadataForm get normalizedForm {
    final String trimmedTitle = _form.title.trim();
    final String? trimmedDescription = _normalizeOptionalText(_form.description);
    return _form.copyWith(
      title: trimmedTitle,
      description: trimmedDescription,
    );
  }

  bool markTitleValidationAttempted() {
    _titleValidationAttempted = true;
    notifyListeners();
    return _form.title.trim().isNotEmpty;
  }

  void updateTitle(String value) {
    _form = _form.copyWith(title: value);
    notifyListeners();
  }

  void updateDescription(String value) {
    _form = _form.copyWith(description: value);
    notifyListeners();
  }

  void updatePublishedAt(DateTime? value) {
    _form = _form.copyWith(publishedAt: value);
    notifyListeners();
  }

  void updateIsR18(bool value) {
    _form = _form.copyWith(isR18: value);
    notifyListeners();
  }

  void addAuthor(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_form.authors.any((Author a) => a.name == trimmed)) return;
    _form = _form.copyWith(
      authors: <Author>[
        ..._form.authors,
        Author(name: trimmed),
      ],
    );
    notifyListeners();
  }

  void removeAuthor(String name) {
    _form = _form.copyWith(
      authors: _form.authors.where((Author a) => a.name != name).toList(),
    );
    notifyListeners();
  }

  void addTagByName(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final Tag tag = Tag(name: trimmed);
    final List<Tag> tags = _form.tags;
    if (tags.any((Tag t) => t.name == tag.name)) return;
    _form = _form.copyWith(tags: <Tag>[...tags, tag]);
    notifyListeners();
  }

  void removeTagByName(String name) {
    final Tag? tag = _form.tags.firstWhereOrNull((Tag t) => t.name == name);
    if (tag == null) return;
    removeTag(tag);
  }

  void removeTag(Tag tag) {
    _form = _form.copyWith(tags: <Tag>[..._form.tags]..remove(tag));
    notifyListeners();
  }

  String? _normalizeOptionalText(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _EditMetadataGeneralTab extends StatelessWidget {
  const _EditMetadataGeneralTab({
    super.key,
    required this.title,
    required this.titleError,
    required this.description,
    required this.publishedAt,
    required this.isR18,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onPublishedAtChanged,
    required this.onIsR18Changed,
  });

  final String title;
  final String? titleError;
  final String description;
  final DateTime? publishedAt;
  final bool isR18;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<DateTime?> onPublishedAtChanged;
  final ValueChanged<bool> onIsR18Changed;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        FluentTextField(
          labelText: '漫画标题',
          initialValue: title,
          errorText: titleError,
          onChanged: onTitleChanged,
          hintText: '修改漫画标题',
        ),
        FluentTextField(
          labelText: '概要',
          initialValue: description,
          maxLines: 4,
          onChanged: onDescriptionChanged,
          hintText: '添加漫画简介…',
        ),
        FluentDatePickerField(
          labelText: '发布日期',
          value: publishedAt,
          onChanged: onPublishedAtChanged,
        ),
        _EditMetadataContentRatingSection(
          isR18: isR18,
          onChanged: onIsR18Changed,
        ),
      ],
    );
  }
}

class _EditMetadataAuthorsTagsTab extends StatelessWidget {
  const _EditMetadataAuthorsTagsTab({
    super.key,
    required this.authors,
    required this.tags,
    required this.onAddAuthor,
    required this.onRemoveAuthor,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final List<Author> authors;
  final List<Tag> tags;
  final ValueChanged<String> onAddAuthor;
  final ValueChanged<String> onRemoveAuthor;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        AuthorLibraryMultiSelectField(
          label: '作者',
          icon: LucideIcons.penTool,
          selectedNames: authors.map((Author a) => a.name).toList(),
          onAdd: onAddAuthor,
          onRemove: onRemoveAuthor,
        ),
        TagLibraryMultiSelectField(
          label: '标签',
          icon: LucideIcons.tag,
          selectedNames: tags.map((Tag t) => t.name).toList(),
          onAdd: onAddTag,
          onRemove: onRemoveTag,
        ),
      ],
    );
  }
}

class _EditMetadataContentRatingSection extends StatelessWidget {
  const _EditMetadataContentRatingSection({
    required this.isR18,
    required this.onChanged,
  });

  final bool isR18;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final Color accent = isR18 ? cs.error : cs.primary;
    final Color cardBg = isR18
        ? cs.error.withValues(alpha: 0.06)
        : cs.primary.withValues(alpha: 0.05);
    final Color borderColor = isR18
        ? cs.error.withValues(alpha: 0.28)
        : cs.hentai.borderSubtle;
    final Color iconBg = isR18
        ? cs.error.withValues(alpha: 0.14)
        : cs.primary.withValues(alpha: 0.12);
    final String headline = isR18 ? 'R18（成人内容）' : '全年龄';
    final String subtitle = isR18 ? '含成人向或限制级描写' : '不含成人向限制级内容';
    final IconData iconData = isR18
        ? LucideIcons.circleAlert
        : LucideIcons.shield;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sm,
      children: <Widget>[
        const FormLabel('年龄限制'),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(tokens.radius.md),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.md,
              vertical: tokens.spacing.sm + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(tokens.radius.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(iconData, size: 20, color: accent),
                  ),
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        headline,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isR18 ? cs.error : cs.hentai.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: tokens.spacing.xs),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: cs.hentai.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.spacing.sm),
                ToggleSwitch(checked: isR18, onChange: () => onChanged(!isR18)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
