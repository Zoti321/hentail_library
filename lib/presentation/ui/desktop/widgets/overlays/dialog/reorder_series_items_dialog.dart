import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/fluent_dialog_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReorderSeriesItemsDialog extends ConsumerStatefulWidget {
  const ReorderSeriesItemsDialog({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<ReorderSeriesItemsDialog> createState() =>
      _ReorderSeriesItemsDialogState();
}

class _ReorderSeriesItemsDialogState
    extends ConsumerState<ReorderSeriesItemsDialog> {
  late List<SeriesItem> _items;
  bool _saving = false;
  final GlobalKey _dialogCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _items = List<SeriesItem>.from(widget.series.items)
      ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  }

  String _labelForComic(String comicId) {
    final title = ref
        .read(libraryPageProvider.notifier)
        .comicById(comicId)
        ?.title;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return comicId.length > 12 ? '${comicId.substring(0, 12)}…' : comicId;
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(librarySeriesRepoProvider)
          .setSeriesItemsOrder(widget.series.name, _items);
      ref.invalidate(allSeriesProvider);
      if (mounted) {
        showSuccessToast(context, '已更新顺序');
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double listHeight = (MediaQuery.sizeOf(context).height * 0.45).clamp(
      280.0,
      480.0,
    );
    return FluentDialogShell(
      cardSurfaceKey: _dialogCardKey,
      title: '调整「${widget.series.name}」内顺序',
      width: 520,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '拖拽左侧手柄排序，数字越小越靠前。',
            style: TextStyle(fontSize: 13, color: cs.textTertiary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: listHeight,
            child: Material(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                dragBoundaryProvider: (BuildContext context) {
                  final BuildContext? cardContext =
                      _dialogCardKey.currentContext;
                  if (cardContext == null) {
                    return null;
                  }
                  final RenderBox? box =
                      cardContext.findRenderObject() as RenderBox?;
                  if (box == null || !box.hasSize) {
                    return null;
                  }
                  final Rect boundary = Rect.fromPoints(
                    box.localToGlobal(Offset.zero),
                    box.localToGlobal(Offset(box.size.width, box.size.height)),
                  );
                  return _GlobalRectDragBoundary(boundary);
                },
                itemCount: _items.length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final SeriesItem item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  final SeriesItem item = _items[index];
                  return Material(
                    key: ValueKey<String>(item.comicId),
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          LucideIcons.gripVertical,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        _labelForComic(item.comicId),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${index + 1} / ${_items.length}',
                        style: TextStyle(fontSize: 11, color: cs.textTertiary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
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
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}

/// Drag clamp to a fixed global [Rect] (here: dialog card), not route overlay.
class _GlobalRectDragBoundary extends DragBoundaryDelegate<Rect> {
  _GlobalRectDragBoundary(this._boundary);

  final Rect _boundary;

  @override
  bool isWithinBoundary(Rect draggedObject) {
    return _boundary.contains(draggedObject.topLeft) &&
        _boundary.contains(draggedObject.bottomRight);
  }

  @override
  Rect nearestPositionWithinBoundary(Rect draggedObject) {
    if (_boundary.right - draggedObject.width < _boundary.left ||
        _boundary.bottom - draggedObject.height < _boundary.top) {
      throw FlutterError(
        'The rect is larger than the boundary. '
        'The rect width must be less than the boundary width, and the rect '
        'height must be less than the boundary height.',
      );
    }
    final double left = clampDouble(
      draggedObject.left,
      _boundary.left,
      _boundary.right - draggedObject.width,
    );
    final double top = clampDouble(
      draggedObject.top,
      _boundary.top,
      _boundary.bottom - draggedObject.height,
    );
    return Rect.fromLTWH(left, top, draggedObject.width, draggedObject.height);
  }
}
