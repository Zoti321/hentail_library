import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/draft/bulk_metadata_edit_session.dart';
import 'package:hentai_library/features/comic/presentation/view_models/bulk_metadata_edit_session_notifier.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_language.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/confirm_dialog.dart';
import 'package:hentai_library/features/comic/presentation/widgets/comic_language_quick_pick.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/comic/presentation/l10n/comic_l10n.dart';

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

  void _selectTabIndex(int index) {
    _selectTab(_BulkEditTab.values[index]);
  }

  void _selectTab(_BulkEditTab tab) {
    setState(() {
      _detailTransitionReverse = tab.index < _tab.index;
      _tab = tab;
    });
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
    final WindowSizeClass sizeClass = windowSizeClassOf(context);
    return _BulkEditScaffold(
      notifier: _sessionNotifier,
      tab: _tab,
      detailTransitionReverse: _detailTransitionReverse,
      fields: _fieldsFor(_tab),
      spacing: M3ETheme.of(context).spacing,
      paneGap: MetadataEditFormMetrics.sectionGap(sizeClass),
      useListDetail: sizeClass.index >= WindowSizeClass.expanded.index,
      onTabIndexSelected: _selectTabIndex,
      onTabSelected: _selectTab,
    );
  }
}

class _BulkEditScaffold extends StatelessWidget {
  const _BulkEditScaffold({
    required this.notifier,
    required this.tab,
    required this.detailTransitionReverse,
    required this.fields,
    required this.spacing,
    required this.paneGap,
    required this.useListDetail,
    required this.onTabIndexSelected,
    required this.onTabSelected,
  });

  final BulkMetadataEditSessionNotifier notifier;
  final _BulkEditTab tab;
  final bool detailTransitionReverse;
  final List<BulkMetadataEditFieldKind> fields;
  final M3ESpacing spacing;
  final double paneGap;
  final bool useListDetail;
  final ValueChanged<int> onTabIndexSelected;
  final ValueChanged<_BulkEditTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final Widget sections = _BulkSectionList(
      notifier: notifier,
      fields: fields,
      spacing: spacing,
    );
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
                _BulkTabBar(selectedTab: tab, onSelected: onTabIndexSelected),
                SizedBox(height: spacing.lg),
              ],
              if (useListDetail)
                _BulkListDetailLayout(
                  notifier: notifier,
                  tab: tab,
                  fields: fields,
                  spacing: spacing,
                  paneGap: paneGap,
                  detailTransitionReverse: detailTransitionReverse,
                  onTabSelected: onTabSelected,
                )
              else
                Expanded(
                  child: ScrollConfiguration(
                    behavior: MetadataEditScrollBehavior(),
                    child: SingleChildScrollView(
                      primary: false,
                      child: sections,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BulkTabBar extends StatelessWidget {
  const _BulkTabBar({required this.selectedTab, required this.onSelected});

  final _BulkEditTab selectedTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SegmentedCapsuleBar(
      segments: <SegmentedCapsuleSegment>[
        SegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabGeneral),
        SegmentedCapsuleSegment(label: l10n.dialogEditMetadataTabAuthorsTags),
      ],
      selectedIndex: selectedTab.index,
      onSelected: onSelected,
    );
  }
}

class _BulkListDetailLayout extends StatelessWidget {
  const _BulkListDetailLayout({
    required this.notifier,
    required this.tab,
    required this.fields,
    required this.spacing,
    required this.paneGap,
    required this.detailTransitionReverse,
    required this.onTabSelected,
  });

  final BulkMetadataEditSessionNotifier notifier;
  final _BulkEditTab tab;
  final List<BulkMetadataEditFieldKind> fields;
  final M3ESpacing spacing;
  final double paneGap;
  final bool detailTransitionReverse;
  final ValueChanged<_BulkEditTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
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
                  selected: tab == _BulkEditTab.general,
                  onTap: () => onTabSelected(_BulkEditTab.general),
                ),
                ListDetailNavItem(
                  label: l10n.dialogEditMetadataTabAuthorsTags,
                  selected: tab == _BulkEditTab.authorsAndTags,
                  onTap: () => onTabSelected(_BulkEditTab.authorsAndTags),
                ),
              ],
            ),
          ),
          SizedBox(width: paneGap),
          Expanded(
            child: ListDetailDetailTransition(
              switchKey: tab,
              reverse: detailTransitionReverse,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal:
                      MetadataEditFormMetrics.detailContentHorizontalInset,
                ),
                child: ScrollConfiguration(
                  behavior: MetadataEditScrollBehavior(),
                  child: SingleChildScrollView(
                    primary: false,
                    child: _BulkSectionList(
                      notifier: notifier,
                      fields: fields,
                      spacing: spacing,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkSectionList extends StatelessWidget {
  const _BulkSectionList({
    required this.notifier,
    required this.fields,
    required this.spacing,
  });

  final BulkMetadataEditSessionNotifier notifier;
  final List<BulkMetadataEditFieldKind> fields;
  final M3ESpacing spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final BulkMetadataEditFieldKind kind in fields) ...<Widget>[
          _BulkFieldSection(kind: kind, notifier: notifier),
          SizedBox(height: spacing.lg),
        ],
      ],
    );
  }
}

class _BulkFieldSection extends StatelessWidget {
  const _BulkFieldSection({required this.kind, required this.notifier});

  final BulkMetadataEditFieldKind kind;
  final BulkMetadataEditSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final String label = _bulkFieldLabel(l10n, kind);
    final String? mixedHint = _bulkMixedHint(l10n, kind, notifier.session);
    final Widget header = _SectionHeader(label: label, hint: mixedHint);

    if (kind == BulkMetadataEditFieldKind.contentRating) {
      final bool isR18 = notifier.session.contentRatingField.isR18;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          header,
          SizedBox(height: spacing.sm),
          SettingsSwitchTile(
            leading: Symbols.eighteen_up_rating,
            title: Text(isR18 ? 'R18' : l10n.filterAgeAllAges),
            description: Text(label),
            value: isR18,
            onChanged: _handleR18Changed,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        header,
        SizedBox(height: spacing.sm),
        _BulkFieldBody(kind: kind, notifier: notifier),
      ],
    );
  }

  void _handleR18Changed(bool value) {
    notifier.mutate((BulkMetadataEditSession session) {
      session.contentRatingField.isR18 = value;
      session.markDirty(kind);
    });
  }
}

class _BulkFieldBody extends StatelessWidget {
  const _BulkFieldBody({required this.kind, required this.notifier});

  final BulkMetadataEditFieldKind kind;
  final BulkMetadataEditSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      BulkMetadataEditFieldKind.description ||
      BulkMetadataEditFieldKind.publishedAt => _BulkScalarBody(
        kind: kind,
        notifier: notifier,
      ),
      BulkMetadataEditFieldKind.languages => _BulkLanguageBody(
        notifier: notifier,
      ),
      BulkMetadataEditFieldKind.tags ||
      BulkMetadataEditFieldKind.authors ||
      BulkMetadataEditFieldKind.parodies ||
      BulkMetadataEditFieldKind.characters => _BulkMultiValueBody(
        kind: kind,
        notifier: notifier,
      ),
      BulkMetadataEditFieldKind.contentRating => const SizedBox.shrink(),
    };
  }
}

class _BulkScalarBody extends StatelessWidget {
  const _BulkScalarBody({required this.kind, required this.notifier});

  final BulkMetadataEditFieldKind kind;
  final BulkMetadataEditSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final BulkMetadataEditSession session = notifier.session;
    final BulkMetadataEditScalarFieldState state = _bulkScalarState(
      session,
      kind,
    );
    final bool enabled = state.op == ComicMetadataBulkScalarOp.replace;
    final Widget editor = kind == BulkMetadataEditFieldKind.description
        ? OutlinedTextField(
            label: _bulkFieldLabel(l10n, kind),
            initialValue: session.descriptionField.description,
            maxLines: 4,
            enabled: enabled,
            onChanged: _handleDescriptionChanged,
          )
        : _Disabled(
            disabled: !enabled,
            child: PublishedDateTextField(
              label: _bulkFieldLabel(l10n, kind),
              value: session.publishedAtField.publishedAt == null
                  ? ''
                  : DateFormat('yyyy-MM-dd')
                        .format(session.publishedAtField.publishedAt!),
              onChanged: _handlePublishedChanged,
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _BulkOpBar(kind: kind, notifier: notifier),
        editor,
      ],
    );
  }

  void _handleDescriptionChanged(String value) {
    notifier.mutate((BulkMetadataEditSession session) {
      session.descriptionField.description = value;
      session.markDirty(kind);
    });
  }

  void _handlePublishedChanged(String value) {
    notifier.mutate((BulkMetadataEditSession session) {
      session.publishedAtField.publishedAt = DateTime.tryParse(value.trim());
      session.markDirty(kind);
    });
  }
}

class _BulkLanguageBody extends StatelessWidget {
  const _BulkLanguageBody({required this.notifier});

  final BulkMetadataEditSessionNotifier notifier;

  static const BulkMetadataEditFieldKind _kind =
      BulkMetadataEditFieldKind.languages;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _BulkOpBar(kind: _kind, notifier: notifier),
        ComicLanguageQuickPick(
          selected: notifier.session.multiFields[_kind]!.values,
          onCanonicalToggled: _handleCanonicalToggled,
        ),
        SizedBox(height: spacing.sm),
        _BulkTagInput(kind: _kind, notifier: notifier),
      ],
    );
  }

  void _handleCanonicalToggled(String canonical) {
    final List<String> values = notifier.session.multiFields[_kind]!.values;
    if (values.contains(canonical)) {
      notifier.mutate((BulkMetadataEditSession session) {
        final BulkMetadataEditMultiValueFieldState field =
            session.multiFields[_kind]!;
        field.values = field.values
            .where((String v) => v != canonical)
            .toList();
        session.markDirty(_kind);
      });
      return;
    }
    notifier.mutate((BulkMetadataEditSession session) {
      final BulkMetadataEditMultiValueFieldState field =
          session.multiFields[_kind]!;
      if (field.values.contains(canonical)) {
        return;
      }
      field.values = <String>[...field.values, canonical];
      session.markDirty(_kind);
    });
  }
}

class _BulkMultiValueBody extends StatelessWidget {
  const _BulkMultiValueBody({required this.kind, required this.notifier});

  final BulkMetadataEditFieldKind kind;
  final BulkMetadataEditSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _BulkOpBar(kind: kind, notifier: notifier),
        _BulkTagInput(kind: kind, notifier: notifier),
      ],
    );
  }
}

class _BulkOpBar extends StatelessWidget {
  const _BulkOpBar({required this.kind, required this.notifier});

  final BulkMetadataEditFieldKind kind;
  final BulkMetadataEditSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    if (kind == BulkMetadataEditFieldKind.description ||
        kind == BulkMetadataEditFieldKind.publishedAt) {
      final BulkMetadataEditScalarFieldState state = _bulkScalarState(
        notifier.session,
        kind,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SegmentedCapsuleBar(
            segments: ComicMetadataBulkScalarOp.values
                .map(
                  (ComicMetadataBulkScalarOp op) => SegmentedCapsuleSegment(
                    label: _bulkScalarOpLabel(l10n, op),
                  ),
                )
                .toList(growable: false),
            selectedIndex: state.op.index,
            onSelected: _handleScalarSelected,
          ),
          SizedBox(height: spacing.sm),
        ],
      );
    }
    final BulkMetadataEditMultiValueFieldState state =
        notifier.session.multiFields[kind]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SegmentedCapsuleBar(
          segments: ComicMetadataBulkMultiValueOp.values
              .map(
                (ComicMetadataBulkMultiValueOp op) =>
                    SegmentedCapsuleSegment(label: _bulkMultiOpLabel(l10n, op)),
              )
              .toList(growable: false),
          selectedIndex: state.op.index,
          onSelected: _handleMultiSelected,
        ),
        SizedBox(height: spacing.sm),
      ],
    );
  }

  void _handleScalarSelected(int index) {
    notifier.mutate((BulkMetadataEditSession session) {
      final BulkMetadataEditScalarFieldState field =
          kind == BulkMetadataEditFieldKind.description
          ? session.descriptionField
          : session.publishedAtField;
      field.op = ComicMetadataBulkScalarOp.values[index];
      session.markDirty(kind);
    });
  }

  void _handleMultiSelected(int index) {
    notifier.mutate((BulkMetadataEditSession session) {
      session.multiFields[kind]!.op =
          ComicMetadataBulkMultiValueOp.values[index];
      session.markDirty(kind);
    });
  }
}

class _BulkTagInput extends StatelessWidget {
  const _BulkTagInput({required this.kind, required this.notifier});

  final BulkMetadataEditFieldKind kind;
  final BulkMetadataEditSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return TagInputField(
      label: _tagInputLabel(l10n, kind),
      tags: notifier.session.multiFields[kind]!.values,
      onTagCommitted: _handleAdded,
      onTagRemoved: _handleRemoved,
    );
  }

  void _handleAdded(String name) {
    notifier.mutate((BulkMetadataEditSession session) {
      final BulkMetadataEditMultiValueFieldState field =
          session.multiFields[kind]!;
      if (field.values.contains(name)) {
        return;
      }
      field.values = <String>[...field.values, name];
      session.markDirty(kind);
    });
  }

  void _handleRemoved(String name) {
    notifier.mutate((BulkMetadataEditSession session) {
      final BulkMetadataEditMultiValueFieldState field =
          session.multiFields[kind]!;
      field.values = field.values.where((String v) => v != name).toList();
      session.markDirty(kind);
    });
  }
}

String _bulkFieldLabel(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
  return switch (kind) {
    BulkMetadataEditFieldKind.tags => l10n.bulkEditMetadataFieldTags,
    BulkMetadataEditFieldKind.authors => l10n.bulkEditMetadataFieldAuthors,
    BulkMetadataEditFieldKind.languages => l10n.bulkEditMetadataFieldLanguages,
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

String _bulkMultiOpLabel(
  AppLocalizations l10n,
  ComicMetadataBulkMultiValueOp op,
) {
  return switch (op) {
    ComicMetadataBulkMultiValueOp.add => l10n.bulkEditMetadataOpAdd,
    ComicMetadataBulkMultiValueOp.remove => l10n.bulkEditMetadataOpRemove,
    ComicMetadataBulkMultiValueOp.replace => l10n.bulkEditMetadataOpReplace,
  };
}

String _bulkScalarOpLabel(AppLocalizations l10n, ComicMetadataBulkScalarOp op) {
  return switch (op) {
    ComicMetadataBulkScalarOp.replace => l10n.bulkEditMetadataOpReplace,
    ComicMetadataBulkScalarOp.clear => l10n.bulkEditMetadataOpClear,
  };
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

BulkMetadataEditScalarFieldState _bulkScalarState(
  BulkMetadataEditSession session,
  BulkMetadataEditFieldKind kind,
) {
  return kind == BulkMetadataEditFieldKind.description
      ? session.descriptionField
      : session.publishedAtField;
}

bool _bulkIsMixed(
  BulkMetadataEditSession session,
  BulkMetadataEditFieldKind kind,
) {
  return switch (kind) {
    BulkMetadataEditFieldKind.description =>
      session.descriptionField.mixedValues,
    BulkMetadataEditFieldKind.publishedAt =>
      session.publishedAtField.mixedValues,
    BulkMetadataEditFieldKind.contentRating =>
      session.contentRatingField.mixedValues,
    BulkMetadataEditFieldKind.languages ||
    BulkMetadataEditFieldKind.authors ||
    BulkMetadataEditFieldKind.tags ||
    BulkMetadataEditFieldKind.parodies ||
    BulkMetadataEditFieldKind.characters =>
      session.multiFields[kind]!.mixedValues,
  };
}

String? _bulkMixedHint(
  AppLocalizations l10n,
  BulkMetadataEditFieldKind kind,
  BulkMetadataEditSession session,
) {
  if (session.isFieldDirty(kind)) {
    return null;
  }
  return _bulkIsMixed(session, kind) ? l10n.bulkEditMetadataMixedValues : null;
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
