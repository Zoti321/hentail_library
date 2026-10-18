import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/form/author_library_multi_select_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_date_picker_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_number_stepper_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_toggle_field.dart';
import 'package:hentai_library/shared/ui/widgets/form/metadata_lock_button.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/shared/ui/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/shared/ui/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/shared/ui/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/dialog_side_tab_bar.dart';
import 'package:hentai_library/features/library_browse/domain/smart_facet_match_preference.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_metadata_editor_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/smart_facet_match_preference_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'edit_metadata_dialog_general_tab.dart';
part 'edit_metadata_dialog_authors_tags_tab.dart';

/// 漫画元数据编辑：medium/expanded 为 dialog，compact 为全页（[AdaptiveFormSurface]）。
const double _kEditMetadataDialogWidth = 720;
const double _kEditMetadataDialogRadius = 4;

/// 壳标题区与底栏的近似高度，用于限制 dialog body 最大滚动区。
const double _kEditMetadataShellChromeReserve = 120;

const double _kEditMetadataBodyMinHeight = 240;

enum _EditMetadataTab { general, authorsAndTags }

/// 打开漫画元数据编辑表面。有 Series 归属时在常规页展示成员排序区。
Future<void> showEditMetadataDialog({
  required BuildContext context,
  required Comic comic,
  SeriesItemMembership? seriesItemSort,
}) {
  return showAdaptiveFormSurfaceWidget<void>(
    context: context,
    surface: EditMetadataDialog(comic: comic, seriesItemSort: seriesItemSort),
  );
}

class EditMetadataDialog extends StatefulHookConsumerWidget {
  const EditMetadataDialog({
    super.key,
    required this.comic,
    this.seriesItemSort,
  });

  final Comic comic;
  final SeriesItemMembership? seriesItemSort;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditMetadataDialogState();
}

class _EditMetadataDialogState extends ConsumerState<EditMetadataDialog> {
  late ComicMetadataForm _form;
  late ComicMetaLocks _locks;
  ComicMetadataFormValidation? _validation;
  _EditMetadataTab _selectedTab = _EditMetadataTab.general;
  bool _saving = false;
  bool _lockBusy = false;

  /// null = 无归属或尚未加载到归属。
  SeriesItemMembership? _seriesSortSeed;
  late String _sortOrderText;
  late bool _sortOrderLocked;
  String? _sortOrderError;

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
    _locks = widget.comic.locks;
    final SeriesItemMembership? seed = widget.seriesItemSort;
    if (seed != null) {
      _applySeriesSortSeed(seed);
    } else {
      _sortOrderText = '';
      _sortOrderLocked = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSeriesSortMembership();
      });
    }
  }

  void _applySeriesSortSeed(SeriesItemMembership seed) {
    _seriesSortSeed = seed;
    _sortOrderText = _formatSortOrder(seed.sortOrder);
    _sortOrderLocked = seed.sortOrderLocked;
  }

  Future<void> _loadSeriesSortMembership() async {
    try {
      final SeriesItemMembership? membership = await ref
          .read(comicMetadataEditorProvider.notifier)
          .findSeriesMembership(widget.comic.comicId);
      if (!mounted) {
        return;
      }
      setState(() {
        if (membership != null) {
          _applySeriesSortSeed(membership);
        } else {
          _seriesSortSeed = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _seriesSortSeed = null;
      });
    }
  }

  Future<void> _setLock({
    bool? title,
    bool? description,
    bool? publishedAt,
    bool? contentRating,
    bool? authors,
    bool? tags,
    bool? languages,
    bool? parodies,
    bool? characters,
  }) async {
    if (_lockBusy) {
      return;
    }
    setState(() => _lockBusy = true);
    try {
      await ref
          .read(comicMetadataEditorProvider.notifier)
          .setLocks(
            widget.comic.comicId,
            title: title,
            description: description,
            publishedAt: publishedAt,
            contentRating: contentRating,
            authors: authors,
            tags: tags,
            languages: languages,
            parodies: parodies,
            characters: characters,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _locks = _locks.copyWith(
          title: title,
          description: description,
          publishedAt: publishedAt,
          contentRating: contentRating,
          authors: authors,
          tags: tags,
          languages: languages,
          parodies: parodies,
          characters: characters,
        );
      });
    } catch (error, stackTrace) {
      logError(AppLog.ui('editMetadata'), '设置元数据字段锁失败', error, stackTrace);
      if (mounted) {
        showCustomToast(
          context,
          message: context.l10n.commonSaveFailedToast,
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _lockBusy = false);
      }
    }
  }

  void _selectTab(int index) {
    if (index == _selectedTab.index) {
      return;
    }
    setState(() {
      _selectedTab = _EditMetadataTab.values[index];
    });
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
        _selectedTab = _EditMetadataTab.general;
      });
      return;
    }

    final SeriesItemMembership? seed = _seriesSortSeed;
    double? parsedSortOrder;
    if (seed != null) {
      final String trimmed = _sortOrderText.trim();
      final double? parsed = double.tryParse(trimmed);
      if (trimmed.isEmpty || parsed == null || !parsed.isFinite) {
        setState(() {
          _sortOrderError = context.l10n.formSeriesItemSortOrderInvalid;
          _selectedTab = _EditMetadataTab.general;
        });
        return;
      }
      parsedSortOrder = parsed;
    }

    setState(() {
      _validation = null;
      _sortOrderError = null;
      _saving = true;
    });
    try {
      final ComicMetadataEditorNotifier editor = ref.read(
        comicMetadataEditorProvider.notifier,
      );
      await editor.apply(_form.normalized, widget.comic);
      if (seed != null && parsedSortOrder != null) {
        await editor.persistSeriesSort(
          comicId: widget.comic.comicId,
          seed: seed,
          sortOrder: parsedSortOrder,
          draftLocked: _sortOrderLocked,
        );
      }
      if (mounted) {
        showSuccessToast(context, context.l10n.commonSavedToast);
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      logError(AppLog.ui('editMetadata'), '保存漫画元数据失败', error, stackTrace);
      if (mounted) {
        showCustomToast(
          context,
          message: context.l10n.commonSaveFailedToast,
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildTabPane(AppThemeTokens tokens) {
    return switch (_selectedTab) {
      _EditMetadataTab.general => _EditMetadataGeneralTab(
        title: _form.title,
        titleError: _validation?.titleError,
        description: _form.description ?? '',
        publishedAt: _form.publishedAt,
        isR18: _form.isR18,
        languages: _form.languages,
        locks: _locks,
        lockBusy: _lockBusy || _saving,
        showSeriesSort: _seriesSortSeed != null,
        sortOrderText: _sortOrderText,
        sortOrderLocked: _sortOrderLocked,
        sortOrderError: _sortOrderError,
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
        onAddLanguage: (String name) {
          _updateForm((ComicMetadataForm f) => f.addLanguage(name));
        },
        onRemoveLanguage: (String name) {
          _updateForm((ComicMetadataForm f) => f.removeLanguage(name));
        },
        onSortOrderChanged: (String value) {
          setState(() {
            _sortOrderText = value;
            if (_sortOrderError != null) {
              _sortOrderError = null;
            }
          });
        },
        onSortOrderLockedChanged: (bool locked) {
          setState(() => _sortOrderLocked = locked);
        },
        onLockChanged: _setLock,
      ),
      _EditMetadataTab.authorsAndTags => _EditMetadataAuthorsTagsTab(
        scope: (
          comicId: widget.comic.comicId,
          title: _form.title,
          resourcePath: widget.comic.path,
          seriesId: _seriesSortSeed?.seriesId,
        ),
        authors: _form.authors,
        tags: _form.tags,
        parodies: _form.parodies,
        characters: _form.characters,
        locks: _locks,
        lockBusy: _lockBusy || _saving,
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
        onAddParody: (String name) {
          _updateForm((ComicMetadataForm f) => f.addParody(name));
        },
        onRemoveParody: (String name) {
          _updateForm((ComicMetadataForm f) => f.removeParody(name));
        },
        onAddCharacter: (String name) {
          _updateForm((ComicMetadataForm f) => f.addCharacter(name));
        },
        onRemoveCharacter: (String name) {
          _updateForm((ComicMetadataForm f) => f.removeCharacter(name));
        },
        onLockChanged: _setLock,
      ),
    };
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
