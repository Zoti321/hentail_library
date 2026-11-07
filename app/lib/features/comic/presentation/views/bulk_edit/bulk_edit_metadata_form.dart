import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/draft/bulk_metadata_edit_session.dart';
import 'package:hentai_library/features/comic/presentation/view_models/bulk_metadata_edit_session_notifier.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/metadata_edit_form_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/confirm_dialog.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_edit_form_scroll.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_field_label_row.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/comic_language_quick_pick.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/outlined_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/published_date_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/tag_input_field.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_detail_transition.dart';
import 'package:hentai_library/shared/ui/widgets/list_detail/list_detail_nav_item.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hentai_library/features/library_admin/public.dart';

/// 批量编辑表单（MD3E）：expanded+ 为 list-detail（常规 / 作者&标签 + 详情区滚动），
/// 较窄宽度为顶部分段 + 纵向滚动。
///
/// 保存时先二次确认，再以 [Navigator.pop] 返回 [ComicMetadataBulkPatch]；
/// 由外层 [showBulkEditMetadata] 的确认按钮通过 [BulkEditMetadataFormState.confirm] 触发。
class BulkEditMetadataForm extends ConsumerStatefulWidget {
  const BulkEditMetadataForm({super.key, required this.comicIds});

  final List<String> comicIds;

  @override
  ConsumerState<BulkEditMetadataForm> createState() =>
      BulkEditMetadataFormState();
}

enum _BulkEditTab { general, authorsAndTags }

List<BulkMetadataEditFieldKind> _fieldsFor(_BulkEditTab tab) {
  return switch (tab) {
    _BulkEditTab.general => <BulkMetadataEditFieldKind>[
      BulkMetadataEditFieldKind.description,
      BulkMetadataEditFieldKind.publishedAt,
      BulkMetadataEditFieldKind.contentRating,
      BulkMetadataEditFieldKind.languages,
    ],
    _BulkEditTab.authorsAndTags => <BulkMetadataEditFieldKind>[
      BulkMetadataEditFieldKind.authors,
      BulkMetadataEditFieldKind.tags,
      BulkMetadataEditFieldKind.parodies,
      BulkMetadataEditFieldKind.characters,
    ],
  };
}

class BulkEditMetadataFormState extends ConsumerState<BulkEditMetadataForm> {
  _BulkEditTab _tab = _BulkEditTab.general;
  bool _detailTransitionReverse = false;

  BulkMetadataEditSessionNotifier get _sessionNotifier =>
      ref.read(bulkMetadataEditSessionProvider(widget.comicIds).notifier);

  BulkMetadataEditSession get _session => _sessionNotifier.session;

  /// 保存入口：校验有改动 → 二次确认 → 返回 patch。无改动时静默返回（与旧弹窗一致）。
  Future<void> confirm() async {
    final AppLocalizations l10n = context.l10n;
    final ComicMetadataBulkPatch? patch = _sessionNotifier.buildPatch();
    if (patch == null) {
      return;
    }
    final bool confirmed = await showConfirmDialog(
      context,
      title: l10n.bulkEditMetadataConfirmTitle,
      content: Text(
        l10n.bulkEditMetadataConfirmBody(
          widget.comicIds.length,
          patch.enabledFieldCount,
        ),
      ),
      confirmLabel: l10n.commonSaveChanges,
    );
    if (!confirmed || !mounted) {
      return;
    }
    Navigator.of(context).pop(patch);
  }

  void _addMultiValue(BulkMetadataEditFieldKind kind, String name) {
    _sessionNotifier.mutate((BulkMetadataEditSession session) {
      final BulkMetadataEditMultiValueFieldState field =
          session.multiFields[kind]!;
      if (field.values.contains(name)) {
        return;
      }
      field.values = <String>[...field.values, name];
      session.markDirty(kind);
    });
  }

  void _removeMultiValue(BulkMetadataEditFieldKind kind, String name) {
    _sessionNotifier.mutate((BulkMetadataEditSession session) {
      final BulkMetadataEditMultiValueFieldState field =
          session.multiFields[kind]!;
      field.values = field.values.where((String v) => v != name).toList();
      session.markDirty(kind);
    });
  }

  void _toggleLanguage(String canonical) {
    final BulkMetadataEditMultiValueFieldState field =
        _session.multiFields[BulkMetadataEditFieldKind.languages]!;
    if (field.values.contains(canonical)) {
      _removeMultiValue(BulkMetadataEditFieldKind.languages, canonical);
    } else {
      _addMultiValue(BulkMetadataEditFieldKind.languages, canonical);
    }
  }

  String _fieldLabel(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    return switch (kind) {
      BulkMetadataEditFieldKind.tags => l10n.bulkEditMetadataFieldTags,
      BulkMetadataEditFieldKind.authors => l10n.bulkEditMetadataFieldAuthors,
      BulkMetadataEditFieldKind.languages =>
        l10n.bulkEditMetadataFieldLanguages,
      BulkMetadataEditFieldKind.parodies => l10n.bulkEditMetadataFieldParodies,
      BulkMetadataEditFieldKind.characters =>
        l10n.bulkEditMetadataFieldCharacters,
      BulkMetadataEditFieldKind.contentRating =>
        l10n.bulkEditMetadataFieldContentRating,
      BulkMetadataEditFieldKind.description =>
        l10n.bulkEditMetadataFieldDescription,
      BulkMetadataEditFieldKind.publishedAt =>
        l10n.bulkEditMetadataFieldPublishedAt,
    };
  }

  String _multiOpLabel(
    AppLocalizations l10n,
    ComicMetadataBulkMultiValueOp op,
  ) {
    return switch (op) {
      ComicMetadataBulkMultiValueOp.add => l10n.bulkEditMetadataOpAdd,
      ComicMetadataBulkMultiValueOp.remove => l10n.bulkEditMetadataOpRemove,
      ComicMetadataBulkMultiValueOp.replace => l10n.bulkEditMetadataOpReplace,
    };
  }

  String _scalarOpLabel(AppLocalizations l10n, ComicMetadataBulkScalarOp op) {
    return switch (op) {
      ComicMetadataBulkScalarOp.replace => l10n.bulkEditMetadataOpReplace,
      ComicMetadataBulkScalarOp.clear => l10n.bulkEditMetadataOpClear,
    };
  }

  BulkMetadataEditScalarFieldState _scalarState(
    BulkMetadataEditFieldKind kind,
  ) {
    return kind == BulkMetadataEditFieldKind.description
        ? _session.descriptionField
        : _session.publishedAtField;
  }

  bool _isMixed(BulkMetadataEditFieldKind kind) {
    return switch (kind) {
      BulkMetadataEditFieldKind.description =>
        _session.descriptionField.mixedValues,
      BulkMetadataEditFieldKind.publishedAt =>
        _session.publishedAtField.mixedValues,
      BulkMetadataEditFieldKind.contentRating =>
        _session.contentRatingField.mixedValues,
      BulkMetadataEditFieldKind.languages ||
      BulkMetadataEditFieldKind.authors ||
      BulkMetadataEditFieldKind.tags ||
      BulkMetadataEditFieldKind.parodies ||
      BulkMetadataEditFieldKind.characters =>
        _session.multiFields[kind]!.mixedValues,
    };
  }

  /// 多种值提示（操作模式由分段胶囊表达，不在标题行重复）。
  String? _mixedHint(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    if (_session.isFieldDirty(kind)) {
      return null;
    }
    return _isMixed(kind) ? l10n.bulkEditMetadataMixedValues : null;
  }

  void _selectTabIndex(int index) {
    _selectTab(_BulkEditTab.values[index]);
  }

  void _selectTab(_BulkEditTab tab) {
    setState(() {
      _detailTransitionReverse = tab.index < _tab.index;
      _tab = tab;
    });
  }

  Widget _scrollPane(Widget child) {
    return ScrollConfiguration(
      behavior: MetadataEditScrollBehavior(),
      child: SingleChildScrollView(primary: false, child: child),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return SegmentedCapsuleBar(
      segments: <SegmentedCapsuleSegment>[
        SegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabGeneral),
        SegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabAuthorsTags),
      ],
      selectedIndex: _tab.index,
      onSelected: _selectTabIndex,
    );
  }

  Widget _buildTabFieldSections(
    AppLocalizations l10n,
    List<BulkMetadataEditFieldKind> fields,
    M3ESpacing spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final BulkMetadataEditFieldKind kind in fields) ...<Widget>[
          _buildSection(l10n, kind),
          SizedBox(height: spacing.lg),
        ],
      ],
    );
  }

  Widget _buildListDetailTabLayout(
    AppLocalizations l10n,
    List<BulkMetadataEditFieldKind> fields,
    M3ESpacing spacing,
    double paneGap,
  ) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: MetadataEditFormMetrics.sideTabColumnWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ListDetailNavItem(
                  label: l10n.dialogEditMetadataTabGeneral,
                  selected: _tab == _BulkEditTab.general,
                  onTap: () => _selectTab(_BulkEditTab.general),
                ),
                ListDetailNavItem(
                  label: l10n.dialogEditMetadataTabAuthorsTags,
                  selected: _tab == _BulkEditTab.authorsAndTags,
                  onTap: () => _selectTab(_BulkEditTab.authorsAndTags),
                ),
              ],
            ),
          ),
          SizedBox(width: paneGap),
          Expanded(
            child: ListDetailDetailTransition(
              switchKey: _tab,
              reverse: _detailTransitionReverse,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal:
                      MetadataEditFormMetrics.detailContentHorizontalInset,
                ),
                child: _scrollPane(
                  _buildTabFieldSections(l10n, fields, spacing),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BulkMetadataEditUiState editUi = ref.watch(
      bulkMetadataEditSessionProvider(widget.comicIds),
    );
    if (editUi.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    final double paneGap = MetadataEditFormMetrics.sectionGap(sizeClass);
    final List<BulkMetadataEditFieldKind> fields = _fieldsFor(_tab);
    final bool useListDetail =
        sizeClass.index >= WindowSizeClass.expanded.index;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight =
            MetadataEditFormMetrics.resolveTabbedViewportHeight(
              context,
              constraints,
            );
        return SizedBox(
          height: viewportHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!useListDetail) ...<Widget>[
                _buildTabBar(l10n),
                SizedBox(height: spacing.lg),
              ],
              if (useListDetail)
                _buildListDetailTabLayout(l10n, fields, spacing, paneGap)
              else
                Expanded(
                  child: _scrollPane(
                    _buildTabFieldSections(l10n, fields, spacing),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final String label = _fieldLabel(l10n, kind);
    final String? mixedHint = _mixedHint(l10n, kind);

    if (kind == BulkMetadataEditFieldKind.contentRating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(label: label, hint: mixedHint),
          SizedBox(height: spacing.sm),
          SettingsSwitchTile(
            leading: Symbols.eighteen_up_rating,
            title: Text(
              _session.contentRatingField.isR18 ? 'R18' : l10n.filterAgeAllAges,
            ),
            description: Text(label),
            value: _session.contentRatingField.isR18,
            onChanged: (bool value) {
              _sessionNotifier.mutate((BulkMetadataEditSession session) {
                session.contentRatingField.isR18 = value;
                session.markDirty(kind);
              });
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(label: label, hint: mixedHint),
        SizedBox(height: spacing.sm),
        ..._buildFieldBody(l10n, kind),
      ],
    );
  }

  List<Widget> _buildFieldBody(
    AppLocalizations l10n,
    BulkMetadataEditFieldKind kind,
  ) {
    final SizedBox gap = SizedBox(height: M3ETheme.of(context).spacing.sm);
    return switch (kind) {
      BulkMetadataEditFieldKind.description ||
      BulkMetadataEditFieldKind.publishedAt => _buildScalarBody(
        l10n,
        kind,
        gap,
      ),
      BulkMetadataEditFieldKind.languages => <Widget>[
        _buildOpBar(l10n, kind, gap),
        ComicLanguageQuickPick(
          selected: _session.multiFields[kind]!.values,
          onCanonicalToggled: _toggleLanguage,
        ),
        gap,
        _buildTagInput(l10n, kind),
      ],
      BulkMetadataEditFieldKind.tags ||
      BulkMetadataEditFieldKind.authors ||
      BulkMetadataEditFieldKind.parodies ||
      BulkMetadataEditFieldKind.characters => <Widget>[
        _buildOpBar(l10n, kind, gap),
        _buildTagInput(l10n, kind),
      ],
      BulkMetadataEditFieldKind.contentRating => const <Widget>[],
    };
  }

  List<Widget> _buildScalarBody(
    AppLocalizations l10n,
    BulkMetadataEditFieldKind kind,
    SizedBox gap,
  ) {
    final BulkMetadataEditScalarFieldState state = _scalarState(kind);
    final bool enabled = state.op == ComicMetadataBulkScalarOp.replace;
    final Widget editor = kind == BulkMetadataEditFieldKind.description
        ? OutlinedTextField(
            label: _fieldLabel(l10n, kind),
            initialValue: _session.descriptionField.description,
            maxLines: 4,
            enabled: enabled,
            onChanged: (String value) {
              _sessionNotifier.mutate((BulkMetadataEditSession session) {
                session.descriptionField.description = value;
                session.markDirty(kind);
              });
            },
          )
        : _Disabled(
            disabled: !enabled,
            child: PublishedDateTextField(
              label: _fieldLabel(l10n, kind),
              value: _session.publishedAtField.publishedAt == null
                  ? ''
                  : DateFormat('yyyy-MM-dd')
                        .format(_session.publishedAtField.publishedAt!),
              onChanged: (String value) {
                _sessionNotifier.mutate((BulkMetadataEditSession session) {
                  session.publishedAtField.publishedAt = DateTime.tryParse(
                    value.trim(),
                  );
                  session.markDirty(kind);
                });
              },
            ),
          );
    return <Widget>[_buildOpBar(l10n, kind, gap), editor];
  }

  Widget _buildOpBar(
    AppLocalizations l10n,
    BulkMetadataEditFieldKind kind,
    SizedBox gap,
  ) {
    if (kind == BulkMetadataEditFieldKind.description ||
        kind == BulkMetadataEditFieldKind.publishedAt) {
      final BulkMetadataEditScalarFieldState state = _scalarState(kind);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SegmentedCapsuleBar(
            segments: ComicMetadataBulkScalarOp.values
                .map(
                  (ComicMetadataBulkScalarOp op) =>
                      SegmentedCapsuleSegment(label: _scalarOpLabel(l10n, op)),
                )
                .toList(growable: false),
            selectedIndex: state.op.index,
            onSelected: (int index) {
              _sessionNotifier.mutate((BulkMetadataEditSession session) {
                final BulkMetadataEditScalarFieldState field =
                    kind == BulkMetadataEditFieldKind.description
                    ? session.descriptionField
                    : session.publishedAtField;
                field.op = ComicMetadataBulkScalarOp.values[index];
                session.markDirty(kind);
              });
            },
          ),
          gap,
        ],
      );
    }
    final BulkMetadataEditMultiValueFieldState state =
        _session.multiFields[kind]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SegmentedCapsuleBar(
          segments: ComicMetadataBulkMultiValueOp.values
              .map(
                (ComicMetadataBulkMultiValueOp op) =>
                    SegmentedCapsuleSegment(label: _multiOpLabel(l10n, op)),
              )
              .toList(growable: false),
          selectedIndex: state.op.index,
          onSelected: (int index) {
            _sessionNotifier.mutate((BulkMetadataEditSession session) {
              session.multiFields[kind]!.op =
                  ComicMetadataBulkMultiValueOp.values[index];
              session.markDirty(kind);
            });
          },
        ),
        gap,
      ],
    );
  }

  String _tagInputLabel(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    return switch (kind) {
      BulkMetadataEditFieldKind.tags => l10n.metadataAddTag,
      BulkMetadataEditFieldKind.authors => l10n.metadataAddAuthor,
      BulkMetadataEditFieldKind.parodies => l10n.metadataAddParody,
      BulkMetadataEditFieldKind.characters => l10n.metadataAddCharacter,
      BulkMetadataEditFieldKind.languages => l10n.comicLanguageLabel(
        ComicLanguageNames.other,
      ),
      BulkMetadataEditFieldKind.description ||
      BulkMetadataEditFieldKind.publishedAt ||
      BulkMetadataEditFieldKind.contentRating => l10n.metadataAdd,
    };
  }

  Widget _buildTagInput(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    return TagInputField(
      label: _tagInputLabel(l10n, kind),
      tags: _session.multiFields[kind]!.values,
      onTagCommitted: (String name) => _addMultiValue(kind, name),
      onTagRemoved: (String name) => _removeMultiValue(kind, name),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MetadataFieldLabelRow(label: label),
        if (hint != null) ...<Widget>[
          SizedBox(height: spacing.xs),
          Text(
            hint!,
            style: theme.typeScale.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// 不可编辑时整体半透明并拦截交互（用于不接受 `enabled` 的日期输入）。
class _Disabled extends StatelessWidget {
  const _Disabled({required this.disabled, required this.child});

  final bool disabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: disabled,
      child: Opacity(opacity: disabled ? 0.38 : 1, child: child),
    );
  }
}
