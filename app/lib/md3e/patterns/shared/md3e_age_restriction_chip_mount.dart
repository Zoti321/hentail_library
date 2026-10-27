import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_age_restriction_chip_slot.dart';

/// 控制年龄限制 chip 的挂载与移除防抖（供详情摘要行复用）。
class Md3eAgeRestrictionChipMount extends StatefulWidget {
  const Md3eAgeRestrictionChipMount({
    super.key,
    required this.visible,
    this.onFullyHidden,
  });

  final bool visible;
  final VoidCallback? onFullyHidden;

  @override
  State<Md3eAgeRestrictionChipMount> createState() =>
      _Md3eAgeRestrictionChipMountState();
}

class _Md3eAgeRestrictionChipMountState extends State<Md3eAgeRestrictionChipMount> {
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = widget.visible;
  }

  @override
  void didUpdateWidget(covariant Md3eAgeRestrictionChipMount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _mounted = true;
    }
  }

  void _onFullyHidden() {
    if (mounted) {
      setState(() => _mounted = false);
      widget.onFullyHidden?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mounted) {
      return const SizedBox.shrink();
    }
    return Md3eComicDetailAgeRestrictionChipSlot(
      visible: widget.visible,
      onFullyHidden: _onFullyHidden,
    );
  }
}
