import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_age_restriction_chip.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';

/// 关闭 [visible] 后延迟收起，避免 knob / 状态切换时摘要行瞬间跳动。
const Duration kMd3eComicDetailAgeRestrictionChipHideDebounce =
    Duration(milliseconds: 300);

/// 带移除防抖与尺寸动画的年龄限制 chip 槽位。
class Md3eComicDetailAgeRestrictionChipSlot extends StatefulWidget {
  const Md3eComicDetailAgeRestrictionChipSlot({
    super.key,
    required this.visible,
    this.onFullyHidden,
  });

  final bool visible;
  final VoidCallback? onFullyHidden;

  @override
  State<Md3eComicDetailAgeRestrictionChipSlot> createState() =>
      _Md3eComicDetailAgeRestrictionChipSlotState();
}

class _Md3eComicDetailAgeRestrictionChipSlotState
    extends State<Md3eComicDetailAgeRestrictionChipSlot> {
  bool _rendered = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _rendered = widget.visible;
  }

  @override
  void didUpdateWidget(covariant Md3eComicDetailAgeRestrictionChipSlot oldWidget) {
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
    _hideTimer = Timer(kMd3eComicDetailAgeRestrictionChipHideDebounce, () {
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
    return AnimatedSize(
      duration: Md3eMotion.durationShort,
      curve: Md3eMotion.curveEmphasized,
      alignment: Alignment.centerLeft,
      child: _rendered
          ? const Md3eComicDetailAgeRestrictionChip()
          : const SizedBox.shrink(),
    );
  }
}
