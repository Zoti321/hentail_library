import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/patterns/comic_detail/comic_detail_age_restriction_chip.dart';
import 'package:hentai_library/shared/ui/motion/spring_size.dart';

/// 关闭 [visible] 后延迟收起，避免 knob / 状态切换时摘要行瞬间跳动。
const Duration kComicDetailAgeRestrictionChipHideDebounce = Duration(
  milliseconds: 300,
);

/// 带移除防抖与尺寸动画的年龄限制 chip 槽位。
class ComicDetailAgeRestrictionChipSlot extends StatefulWidget {
  const ComicDetailAgeRestrictionChipSlot({
    super.key,
    required this.visible,
    this.onFullyHidden,
  });

  final bool visible;
  final VoidCallback? onFullyHidden;

  @override
  State<ComicDetailAgeRestrictionChipSlot> createState() =>
      _ComicDetailAgeRestrictionChipSlotState();
}

class _ComicDetailAgeRestrictionChipSlotState
    extends State<ComicDetailAgeRestrictionChipSlot> {
  bool _rendered = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _rendered = widget.visible;
  }

  @override
  void didUpdateWidget(
    covariant ComicDetailAgeRestrictionChipSlot oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _hideTimer?.cancel();
      _hideTimer = null;
      if (!_rendered) {
        setState(() => _rendered = true);
      }
      return;
    }
    if (!_rendered) {
      return;
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(kComicDetailAgeRestrictionChipHideDebounce, () {
      if (!mounted || widget.visible) {
        return;
      }
      setState(() => _rendered = false);
      widget.onFullyHidden?.call();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpringSize(
      expanded: _rendered,
      alignment: Alignment.centerLeft,
      child: const ComicDetailAgeRestrictionChip(),
    );
  }
}
