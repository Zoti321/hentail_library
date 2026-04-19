import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/domain/entity/comic/author.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/domain/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/foundation/my_toggle_switch.dart';
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
    final theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;

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
                  color: theme.colorScheme.cardShadowHover,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: theme.colorScheme.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditMetadataDialogHeader(
                  borderSubtle: theme.colorScheme.borderSubtle,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.xl,
                      vertical: tokens.spacing.lg + 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: tokens.spacing.lg + 4,
                      children: [
                        _EditMetadataTitleSection(
                          title: _controller.form.title,
                          onChanged: _controller.updateTitle,
                        ),
                        _EditMetadataContentRatingSection(
                          isR18: _controller.form.isR18,
                          onChanged: _controller.updateIsR18,
                        ),
                        _EditMetadataAuthorsSection(
                          authors: _controller.form.authors,
                          onAdd: _controller.addAuthor,
                          onRemove: _controller.removeAuthor,
                        ),
                        _EditMetadataTagsSection(
                          tags: _controller.form.tags,
                          onAdd: _controller.addTagByName,
                          onRemove: _controller.removeTagByName,
                        ),
                      ],
                    ),
                  ),
                ),
                _EditMetadataDialogFooter(
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

class _EditMetadataDialogHeader extends StatelessWidget {
  const _EditMetadataDialogHeader({required this.borderSubtle});

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '编辑元数据',
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

class _EditMetadataDialogFooter extends StatelessWidget {
  const _EditMetadataDialogFooter({
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('取消'),
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
                : const Text('保存更改'),
          ),
        ],
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.sm,
      children: [
        const FormLabel('内容分级'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                isR18 ? 'R18（成人内容）' : '全年龄',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isR18 ? cs.error : cs.textSecondary,
                ),
              ),
            ),
            MyToggleSwitch(checked: isR18, onChange: () => onChanged(!isR18)),
          ],
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
