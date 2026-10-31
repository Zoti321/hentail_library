import 'package:flutter/material.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_back_header.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_status_scaffold.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_comics_providers.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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
import 'package:hentai_library/features/library_browse/domain/smart_facet_match_preference.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_metadata_editor_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/smart_facet_match_preference_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

part 'comic_metadata_edit_general_tab.dart';
part 'comic_metadata_edit_authors_tags_tab.dart';

enum _EditMetadataTab { general, authorsAndTags }

/// 生产漫画元数据编辑整页（MD3E）：按 id 加载后渲染 [ComicMetadataEditMd3eView]。
class ComicMetadataEditMd3ePage extends ConsumerWidget {
  const ComicMetadataEditMd3ePage({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Comic?> comicAsync = ref.watch(
      libraryComicDetailProvider(comicId),
    );
    return M3ETheme(
      data: md3eWithAppFontFamily(M3ETheme.of(context)),
      child: comicAsync.when(
        data: (Comic? comic) {
          if (comic == null) {
            return DetailNotFoundStatus(
              icon: LucideIcons.bookOpen,
              label: context.l10n.comicDetailNotFound,
            );
          }
          return ComicMetadataEditMd3eView(comic: comic);
        },
        loading: () => const DetailLoadingStatus(),
        error: (Object error, StackTrace stackTrace) => DetailErrorStatus(
          label: context.l10n.comicDetailLoadFailedRetry,
          onRetry: ref.read(libraryRefreshActionProvider),
        ),
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
      ),
    );
  }
}

/// 漫画元数据编辑表单视图（已加载实体）。
class ComicMetadataEditMd3eView extends StatefulHookConsumerWidget {
  const ComicMetadataEditMd3eView({super.key, required this.comic});

  final Comic comic;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ComicMetadataEditMd3eViewState();
}

class _ComicMetadataEditMd3eViewState
    extends ConsumerState<ComicMetadataEditMd3eView> {
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
    _sortOrderText = '';
    _sortOrderLocked = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeriesSortMembership();
    });
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

  void _leaveAfterSave() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    DetailBackHeader.popOrGoLibrary(context);
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
        _leaveAfterSave();
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
    final AppLocalizations l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const DetailBackHeader(),
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
                  selectedIndex: _selectedTab.index,
                  onSelected: _selectTab,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
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
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.spacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => DetailBackHeader.popOrGoLibrary(context),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
