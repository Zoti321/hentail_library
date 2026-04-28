import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/model/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/foundation/my_toggle_switch.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/fluent_dialog_shell.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// [FluentDialogShell] 标题区、内容区底边距与底栏的近似高度，用于限制中间滚动区。
const double _kEditMetadataShellChromeReserve = 168;

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialForm = ComicMetadataForm(
      title: widget.comic.title,
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
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.form);
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
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return FluentDialogShell(
      title: '编辑元数据',
      width: 580,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: math.max(
            260,
            MediaQuery.sizeOf(context).height * 0.88 -
                _kEditMetadataShellChromeReserve,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spacing.lg,
            children: [
              _EditMetadataTitleSection(
                title: _controller.form.title,
                onChanged: _controller.updateTitle,
              ),
              _EditMetadataContentRatingSection(
                isR18: _controller.form.isR18,
                onChanged: _controller.updateIsR18,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _EditMetadataAuthorsSection(
                      authors: _controller.form.authors,
                      onAdd: _controller.addAuthor,
                      onRemove: _controller.removeAuthor,
                    ),
                  ),
                  SizedBox(width: tokens.spacing.lg),
                  Expanded(
                    child: _EditMetadataTagsSection(
                      tags: _controller.form.tags,
                      onAdd: _controller.addTagByName,
                      onRemove: _controller.removeTagByName,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _saving ? null : _handleSave,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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

  ComicMetadataForm get form => _form;

  void updateTitle(String value) {
    _form = _form.copyWith(title: value);
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
      authors: [
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
    if (tags.any((t) => t.name == tag.name)) return;
    _form = _form.copyWith(tags: [...tags, tag]);
    notifyListeners();
  }

  void removeTagByName(String name) {
    final Tag? tag = _form.tags.firstWhereOrNull((t) => t.name == name);
    if (tag == null) return;
    removeTag(tag);
  }

  void removeTag(Tag tag) {
    _form = _form.copyWith(tags: [..._form.tags]..remove(tag));
    notifyListeners();
  }
}

class _EditMetadataTitleSection extends StatelessWidget {
  const _EditMetadataTitleSection({
    required this.title,
    required this.onChanged,
  });

  final String title;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return FluentTextField(
      labelText: '漫画标题',
      initialValue: title,
      onChanged: onChanged,
      hintText: '修改漫画标题',
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
        : cs.borderSubtle;
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
      children: [
        const FormLabel('内容分级'),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(tokens.radius.md),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
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
              children: [
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
                    children: [
                      Text(
                        headline,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isR18 ? cs.error : cs.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: tokens.spacing.xs),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: cs.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.spacing.sm),
                MyToggleSwitch(
                  checked: isR18,
                  onChange: () => onChanged(!isR18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EditMetadataAuthorsSection extends StatelessWidget {
  const _EditMetadataAuthorsSection({
    required this.authors,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Author> authors;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return AuthorLibraryMultiSelectField(
      label: '作者',
      icon: LucideIcons.penTool,
      selectedNames: authors.map((Author a) => a.name).toList(),
      onAdd: onAdd,
      onRemove: onRemove,
    );
  }
}

class _EditMetadataTagsSection extends StatelessWidget {
  const _EditMetadataTagsSection({
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Tag> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return TagLibraryMultiSelectField(
      label: '标签',
      icon: LucideIcons.tag,
      selectedNames: tags.map((Tag t) => t.name).toList(),
      onAdd: onAdd,
      onRemove: onRemove,
    );
  }
}
