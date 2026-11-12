import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/presentation/views/metadata/metadata_actions.dart';
import 'package:hentai_library/shared/di/author_detail_providers.dart';
import 'package:hentai_library/design-system/components/menu/anchored_menu.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 名称 chip：显示附着数量；合并选择时目标为主色、来源为错误色；
/// 作者可点击查看详情，其他维度长按 / 右键打开「重命名 · 合并 · 删除」菜单。
class MetadataFacetChip extends ConsumerWidget {
  const MetadataFacetChip({
    required this.kind,
    required this.name,
    required this.attachmentCount,
    required this.verified,
    this.mergeTarget,
    this.isMergeSource = false,
    this.onMergeTargetSelected,
    this.onMergeSourceSelected,
    this.onMergeSelectionExited,
    super.key,
  });

  final ManagedNamedFacetKind kind;
  final String name;
  final int? attachmentCount;
  final bool verified;
  final String? mergeTarget;
  final bool isMergeSource;
  final ValueChanged<String>? onMergeTargetSelected;
  final ValueChanged<String>? onMergeSourceSelected;
  final VoidCallback? onMergeSelectionExited;

  bool get _isAuthor => kind == ManagedNamedFacetKind.author;

  bool _isDesktop(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => false,
    };
  }

  void _showMenu(BuildContext context, WidgetRef ref, Offset globalPosition) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    showPointerContextMenu<void>(
      context: context,
      globalPosition: globalPosition,
      children: <M3EMenuNode>[
        M3EMenuEntry(
          label: l10n.metadataRename,
          leading: const Icon(LucideIcons.pencil),
          onPressed: () =>
              unawaited(renameNamedFacet(context, ref, kind, name)),
        ),
        M3EMenuEntry(
          label: l10n.metadataMerge,
          leading: const Icon(LucideIcons.merge),
          enabled: !_isAuthor,
          onPressed: () => onMergeTargetSelected?.call(name),
        ),
        M3EMenuEntry(
          label: l10n.metadataDelete,
          leading: Icon(LucideIcons.trash2, color: scheme.error),
          isDestructive: true,
          onPressed: () =>
              unawaited(deleteNamedFacet(context, ref, kind, name)),
        ),
      ],
    );
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    if (mergeTarget != null) {
      if (mergeTarget == name) {
        onMergeSelectionExited?.call();
      } else {
        onMergeSourceSelected?.call(name);
      }
      return;
    }
    if (_isAuthor) {
      unawaited(ref.read(authorDetailPortProvider).showByName(context, name));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool isMergeTarget = mergeTarget == name;
    final bool selected = isMergeTarget || isMergeSource;
    final bool desktop = _isDesktop(context);
    final bool inMergeMode = mergeTarget != null;

    final String label = (!_isAuthor && attachmentCount != null)
        ? '$name $attachmentCount'
        : name;

    final Widget? leading = isMergeTarget
        ? Icon(Symbols.merge, size: 16, color: scheme.primary)
        : isMergeSource
        ? Icon(Symbols.link_off, size: 16, color: scheme.error)
        : verified
        ? Icon(Symbols.verified, size: 16, color: scheme.primary)
        : null;

    final Widget chip = M3EChip(
      label: label,
      type: selected ? M3EChipType.filter : M3EChipType.suggestion,
      selected: selected,
      leading: leading,
      onPressed: () => _onTap(context, ref),
    );

    if (_isAuthor || inMergeMode) {
      return chip;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: desktop
          ? null
          : () {
              final RenderBox box = context.findRenderObject()! as RenderBox;
              _showMenu(context, ref, box.localToGlobal(Offset.zero));
            },
      onSecondaryTapUp: desktop
          ? (TapUpDetails details) =>
                _showMenu(context, ref, details.globalPosition)
          : null,
      child: chip,
    );
  }
}
