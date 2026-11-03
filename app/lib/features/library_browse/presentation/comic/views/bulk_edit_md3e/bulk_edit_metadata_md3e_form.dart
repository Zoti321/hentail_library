import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/draft/bulk_metadata_edit_session.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/patterns/dialog/md3e_confirm_dialog.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_field_label_row.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/comic_language_quick_pick.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/outlined_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/published_date_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/tag_input_field.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hentai_library/features/library_admin/public.dart';

/// 批量编辑表单（MD3E）：分段切换两组字段，每个字段带操作选择（添加/移除/替换 或 替换/清空）。
///
/// 保存时先二次确认，再以 [Navigator.pop] 返回 [ComicMetadataBulkPatch]；
/// 由外层 [showBulkEditMetadataMd3e] 的确认按钮通过 [BulkEditMetadataMd3eFormState.confirm] 触发。
class BulkEditMetadataMd3eForm extends ConsumerStatefulWidget {
  const BulkEditMetadataMd3eForm({super.key, required this.comicIds});

  final List<String> comicIds;

  @override
  ConsumerState<BulkEditMetadataMd3eForm> createState() =>
      BulkEditMetadataMd3eFormState();
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

class BulkEditMetadataMd3eFormState
    extends ConsumerState<BulkEditMetadataMd3eForm> {
  final BulkMetadataEditSession _session = BulkMetadataEditSession();
  _BulkEditTab _tab = _BulkEditTab.general;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMixedHints();
  }

  Future<void> _loadMixedHints() async {
    final List<Comic> comics = await ref.read(
      bulkEditComicsByIdsProvider(widget.comicIds).future,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _session.applyMixedHintsFromComics(comics);
      _loading = false;
    });
  }

  /// 保存入口：校验有改动 → 二次确认 → 返回 patch。无改动时静默返回（与旧弹窗一致）。
  Future<void> confirm() async {
    final AppLocalizations l10n = context.l10n;
    final ComicMetadataBulkPatch? patch = _session.buildPatch();
    if (patch == null) {
      return;
    }
    final bool confirmed = await showMd3eConfirmDialog(
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

  void _edited(BulkMetadataEditFieldKind kind) {
    setState(() => _session.markDirty(kind));
  }

  void _addMultiValue(BulkMetadataEditFieldKind kind, String name) {
    final BulkMetadataEditMultiValueFieldState field =
        _session.multiFields[kind]!;
    if (field.values.contains(name)) {
      return;
    }
    field.values = <String>[...field.values, name];
    _edited(kind);
  }

  void _removeMultiValue(BulkMetadataEditFieldKind kind, String name) {
    final BulkMetadataEditMultiValueFieldState field =
        _session.multiFields[kind]!;
    field.values = field.values.where((String v) => v != name).toList();
    _edited(kind);
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

  /// 字段已改动时显示摘要；否则若存在混合值则提示「多个值」。
  String? _statusText(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    if (_session.isFieldDirty(kind)) {
      return switch (kind) {
        BulkMetadataEditFieldKind.languages ||
        BulkMetadataEditFieldKind.authors ||
        BulkMetadataEditFieldKind.tags ||
        BulkMetadataEditFieldKind.parodies ||
        BulkMetadataEditFieldKind.characters => () {
          final BulkMetadataEditMultiValueFieldState state =
              _session.multiFields[kind]!;
          return l10n.bulkEditMetadataFieldSummaryCount(
            _multiOpLabel(l10n, state.op),
            state.values.length,
          );
        }(),
        BulkMetadataEditFieldKind.description ||
        BulkMetadataEditFieldKind.publishedAt => _scalarOpLabel(
          l10n,
          _scalarState(kind).op,
        ),
        BulkMetadataEditFieldKind.contentRating =>
          _session.contentRatingField.isR18 ? 'R18' : l10n.filterAgeAllAges,
      };
    }
    return _isMixed(kind) ? l10n.bulkEditMetadataMixedValues : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eSegmentedCapsuleBar(
          segments: <Md3eSegmentedCapsuleSegment>[
            Md3eSegmentedCapsuleSegment(
              label: l10n.dialogEditMetadataTabGeneral,
            ),
            Md3eSegmentedCapsuleSegment(
              label: l10n.dialogEditMetadataTabAuthorsTags,
            ),
          ],
          selectedIndex: _tab.index,
          onSelected: (int index) {
            setState(() => _tab = _BulkEditTab.values[index]);
          },
        ),
        SizedBox(height: spacing.lg),
        for (final BulkMetadataEditFieldKind kind in _fieldsFor(
          _tab,
        )) ...<Widget>[_buildSection(l10n, kind), SizedBox(height: spacing.lg)],
      ],
    );
  }

  Widget _buildSection(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    final String label = _fieldLabel(l10n, kind);
    final String? status = _statusText(l10n, kind);

    if (kind == BulkMetadataEditFieldKind.contentRating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(label: label, status: status),
          SizedBox(height: spacing.sm),
          Md3eSettingsSwitchTile(
            leading: Symbols.eighteen_up_rating,
            title: Text(
              _session.contentRatingField.isR18 ? 'R18' : l10n.filterAgeAllAges,
            ),
            description: Text(label),
            value: _session.contentRatingField.isR18,
            onChanged: (bool value) {
              _session.contentRatingField.isR18 = value;
              _edited(kind);
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(label: label, status: status),
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
        Md3eComicLanguageQuickPick(
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
        ? Md3eOutlinedTextField(
            label: _fieldLabel(l10n, kind),
            initialValue: _session.descriptionField.description,
            maxLines: 4,
            enabled: enabled,
            onChanged: (String value) {
              _session.descriptionField.description = value;
              _edited(kind);
            },
          )
        : _Disabled(
            disabled: !enabled,
            child: Md3ePublishedDateTextField(
              label: _fieldLabel(l10n, kind),
              value: _session.publishedAtField.publishedAt == null
                  ? ''
                  : DateFormat('yyyy-MM-dd')
                        .format(_session.publishedAtField.publishedAt!),
              onChanged: (String value) {
                _session.publishedAtField.publishedAt = DateTime.tryParse(
                  value.trim(),
                );
                _edited(kind);
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
          Md3eSegmentedCapsuleBar(
            segments: ComicMetadataBulkScalarOp.values
                .map(
                  (ComicMetadataBulkScalarOp op) => Md3eSegmentedCapsuleSegment(
                    label: _scalarOpLabel(l10n, op),
                  ),
                )
                .toList(growable: false),
            selectedIndex: state.op.index,
            onSelected: (int index) {
              setState(() {
                state.op = ComicMetadataBulkScalarOp.values[index];
              });
              _edited(kind);
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
        Md3eSegmentedCapsuleBar(
          segments: ComicMetadataBulkMultiValueOp.values
              .map(
                (ComicMetadataBulkMultiValueOp op) =>
                    Md3eSegmentedCapsuleSegment(label: _multiOpLabel(l10n, op)),
              )
              .toList(growable: false),
          selectedIndex: state.op.index,
          onSelected: (int index) {
            setState(() {
              state.op = ComicMetadataBulkMultiValueOp.values[index];
            });
            _edited(kind);
          },
        ),
        gap,
      ],
    );
  }

  Widget _buildTagInput(AppLocalizations l10n, BulkMetadataEditFieldKind kind) {
    return Md3eTagInputField(
      label: l10n.metadataAdd,
      tags: _session.multiFields[kind]!.values,
      maxWidth: double.infinity,
      onTagCommitted: (String name) => _addMultiValue(kind, name),
      onTagRemoved: (String name) => _removeMultiValue(kind, name),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.status});

  final String label;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Row(
      children: <Widget>[
        Expanded(child: Md3eMetadataFieldLabelRow(label: label)),
        if (status != null)
          Text(
            status!,
            style: theme.typeScale.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
