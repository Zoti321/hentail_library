import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_date_picker_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_toggle_field.dart';
import 'package:hentai_library/ui/core/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/dialog_side_tab_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 漫画元数据编辑：medium/expanded 为 dialog，compact 为全页（[AdaptiveFormSurface]）。
const double _kEditMetadataDialogWidth = 720;
const double _kEditMetadataDialogRadius = 4;

/// 壳标题区与底栏的近似高度，用于限制 dialog body 最大滚动区。
const double _kEditMetadataShellChromeReserve = 120;

const double _kEditMetadataBodyMinHeight = 240;

const Duration _kEditMetadataTabTransitionDuration = Duration(
  milliseconds: 180,
);

enum _EditMetadataTab { general, authorsAndTags }

/// 打开漫画元数据编辑表面。
Future<void> showEditMetadataDialog({
  required BuildContext context,
  required Comic comic,
  required Future<void> Function(ComicMetadataForm) onSave,
}) {
  return showAdaptiveFormSurfaceWidget<void>(
    context: context,
    surface: EditMetadataDialog(comic: comic, onSave: onSave),
  );
}

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
  late ComicMetadataForm _form;
  ComicMetadataFormValidation? _validation;
  _EditMetadataTab _selectedTab = _EditMetadataTab.general;
  int _previousTabIndex = 0;
  bool _saving = false;

  List<DialogSideTabItem> _sideTabs(AppLocalizations l10n) =>
      <DialogSideTabItem>[
        DialogSideTabItem(
          label: l10n.dialogEditMetadataTabGeneral,
          icon: LucideIcons.textAlignCenter,
        ),
        DialogSideTabItem(
          label: l10n.dialogEditMetadataTabAuthorsTags,
          icon: LucideIcons.users,
        ),
      ];

  List<CapsuleTabItem> _capsuleTabs(AppLocalizations l10n) => <CapsuleTabItem>[
    CapsuleTabItem(
      label: l10n.dialogEditMetadataTabGeneral,
      icon: LucideIcons.textAlignCenter,
    ),
    CapsuleTabItem(
      label: l10n.dialogEditMetadataTabAuthorsTags,
      icon: LucideIcons.users,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _form = ComicMetadataForm.fromComic(widget.comic);
  }

  void _selectTab(int index) {
    if (index == _selectedTab.index) {
      return;
    }
    setState(() {
      _previousTabIndex = _selectedTab.index;
      _selectedTab = _EditMetadataTab.values[index];
    });
  }

  String _tabChildKey(_EditMetadataTab tab) {
    return switch (tab) {
      _EditMetadataTab.general => 'general',
      _EditMetadataTab.authorsAndTags => 'authors-tags',
    };
  }

  Widget _buildTabTransition(Widget child, Animation<double> animation) {
    final bool slideForward = _selectedTab.index > _previousTabIndex;
    final double direction = slideForward ? 1 : -1;
    final bool isIncoming =
        child.key == ValueKey<String>(_tabChildKey(_selectedTab));
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    final Animation<Offset> offsetAnimation = isIncoming
        ? Tween<Offset>(
            begin: Offset(0.08 * direction, 0),
            end: Offset.zero,
          ).animate(curved)
        : Tween<Offset>(
            begin: Offset.zero,
            end: Offset(-0.08 * direction, 0),
          ).animate(curved);

    return ClipRect(
      child: SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: isIncoming ? animation : ReverseAnimation(animation),
          child: child,
        ),
      ),
    );
  }

  void _updateForm(ComicMetadataForm Function(ComicMetadataForm) transform) {
    setState(() => _form = transform(_form));
  }

  Future<void> _handleSave() async {
    if (_saving) {
      return;
    }
    final ComicMetadataFormValidation validation = _form.validate();
    if (!validation.isValid) {
      setState(() {
        _validation = validation;
        _previousTabIndex = _selectedTab.index;
        _selectedTab = _EditMetadataTab.general;
      });
      return;
    }
    setState(() {
      _validation = null;
      _saving = true;
    });
    try {
      await widget.onSave(_form.normalized);
      if (mounted) {
        showSuccessToast(context, context.l10n.commonSavedToast);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildTabPane(AppThemeTokens tokens) {
    return AnimatedSwitcher(
      duration: _kEditMetadataTabTransitionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: _buildTabTransition,
      child: switch (_selectedTab) {
        _EditMetadataTab.general => _EditMetadataGeneralTab(
          key: const ValueKey<String>('general'),
          title: _form.title,
          titleError: _validation?.titleError,
          description: _form.description ?? '',
          publishedAt: _form.publishedAt,
          isR18: _form.isR18,
          onTitleChanged: (String value) {
            setState(() {
              _form = _form.copyWith(title: value);
              if (_validation?.titleError != null) {
                _validation = const ComicMetadataFormValidation();
              }
            });
          },
          onDescriptionChanged: (String value) {
            _updateForm((ComicMetadataForm f) => f.copyWith(description: value));
          },
          onPublishedAtChanged: (DateTime? value) {
            _updateForm((ComicMetadataForm f) => f.copyWith(publishedAt: value));
          },
          onIsR18Changed: (bool value) {
            _updateForm((ComicMetadataForm f) => f.copyWith(isR18: value));
          },
        ),
        _EditMetadataTab.authorsAndTags => _EditMetadataAuthorsTagsTab(
          key: const ValueKey<String>('authors-tags'),
          authors: _form.authors,
          tags: _form.tags,
          onAddAuthor: (String name) {
            _updateForm((ComicMetadataForm f) => f.addAuthor(name));
          },
          onRemoveAuthor: (String name) {
            _updateForm((ComicMetadataForm f) => f.removeAuthor(name));
          },
          onAddTag: (String name) {
            _updateForm((ComicMetadataForm f) => f.addTag(name));
          },
          onRemoveTag: (String name) {
            _updateForm((ComicMetadataForm f) => f.removeTag(name));
          },
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final int selectedTabIndex = _selectedTab.index;
    final bool compact = AppLayoutBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );

    final Widget body;
    if (compact) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.lg,
              0,
              tokens.spacing.lg,
              tokens.spacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CapsuleTabBar(
                items: _capsuleTabs(l10n),
                selectedIndex: selectedTabIndex,
                onSelected: _selectTab,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.lg,
                0,
                tokens.spacing.lg,
                tokens.spacing.xs,
              ),
              child: _buildTabPane(tokens),
            ),
          ),
        ],
      );
    } else {
      body = ConstrainedBox(
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
              items: _sideTabs(l10n),
              selectedIndex: selectedTabIndex,
              showDivider: false,
              onSelected: _selectTab,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.lg,
                  0,
                  18,
                  tokens.spacing.xs,
                ),
                child: _buildTabPane(tokens),
              ),
            ),
          ],
        ),
      );
    }

    return AdaptiveFormSurface(
      title: l10n.dialogEditMetadataTitle,
      maxDialogWidth: _kEditMetadataDialogWidth,
      borderRadius: _kEditMetadataDialogRadius,
      scrollableBody: false,
      bodyPadding: EdgeInsets.zero,
      backgroundColor: cs.surface,
      showFooterDivider: false,
      fitContentHeight: true,
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      body: body,
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
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
              : Text(l10n.commonSaveChanges),
        ),
      ],
    );
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
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final bool compact = AppLayoutBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );

    final Widget publishedAtField = FluentDatePickerField(
      labelText: l10n.formPublishedDateLabel,
      value: publishedAt,
      onChanged: onPublishedAtChanged,
    );
    final Widget contentRatingField = FluentToggleField(
      labelText: l10n.formAgeRestrictionLabel,
      value: isR18,
      onChanged: onIsR18Changed,
      checkedLabel: 'R18',
      uncheckedLabel: l10n.filterAgeAllAges,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        FluentTextField(
          labelText: l10n.formComicTitleLabel,
          initialValue: title,
          errorText: titleError,
          onChanged: onTitleChanged,
          hintText: l10n.formComicTitleHint,
        ),
        FluentTextField(
          labelText: l10n.formComicDescriptionLabel,
          initialValue: description,
          maxLines: 4,
          onChanged: onDescriptionChanged,
          hintText: l10n.formComicDescriptionHint,
        ),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spacing.lg,
            children: <Widget>[publishedAtField, contentRatingField],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.spacing.md,
            children: <Widget>[
              Expanded(flex: 3, child: publishedAtField),
              Expanded(flex: 2, child: contentRatingField),
            ],
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
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        AuthorLibraryMultiSelectField(
          label: l10n.comicDetailAuthors,
          icon: LucideIcons.penTool,
          selectedNames: authors.map((Author a) => a.name).toList(),
          onAdd: onAddAuthor,
          onRemove: onRemoveAuthor,
        ),
        TagLibraryMultiSelectField(
          label: l10n.comicDetailTags,
          icon: LucideIcons.tag,
          selectedNames: tags.map((Tag t) => t.name).toList(),
          onAdd: onAddTag,
          onRemove: onRemoveTag,
        ),
      ],
    );
  }
}
