import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/metadata_md3e_actions.dart';
import 'package:hentai_library/shared/di/author_detail_providers.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/context_menu/named_facet_context_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 名称 chip：显示附着数量；合并选择时目标为主色、来源为错误色；
/// 作者可点击查看详情，其他维度长按 / 右键打开「重命名 · 合并 · 删除」菜单。
class MetadataMd3eFacetChip extends ConsumerWidget {
  const MetadataMd3eFacetChip({
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

  void _showMenu(BuildContext context, WidgetRef ref, Offset position) {
    NamedFacetContextMenu.show(
      context,
      position: position,
      mergeEnabled: !_isAuthor,
      onAction: (NamedFacetContextAction action) {
        switch (action) {
          case NamedFacetContextAction.rename:
            unawaited(renameNamedFacet(context, ref, kind, name));
          case NamedFacetContextAction.merge:
            onMergeTargetSelected?.call(name);
          case NamedFacetContextAction.delete:
            unawaited(deleteNamedFacet(context, ref, kind, name));
        }
      },
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

    final Color selectedColor = isMergeTarget
        ? scheme.primaryContainer
        : scheme.errorContainer;

    final Widget chip = FilterChip(
      showCheckmark: false,
      selected: selected,
      selectedColor: selectedColor,
      avatar: verified
          ? Icon(Symbols.verified, size: 16, color: scheme.primary)
          : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
          if (!_isAuthor && attachmentCount != null) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              '$attachmentCount',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
      onSelected: (_) => _onTap(context, ref),
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
