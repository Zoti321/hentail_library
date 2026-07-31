import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const Duration kLibraryFilterAccordionDuration = Duration(milliseconds: 200);
const Curve kLibraryFilterAccordionCurve = Curves.easeOutCubic;

/// 筛选手风琴展开内容：高度动画（收起为 [SizedBox.shrink]）。
class LibraryFilterAccordionBody extends StatelessWidget {
  const LibraryFilterAccordionBody({
    super.key,
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: kLibraryFilterAccordionDuration,
      curve: kLibraryFilterAccordionCurve,
      alignment: Alignment.topCenter,
      child: expanded ? child : const SizedBox.shrink(),
    );
  }
}

/// 筛选手风琴 chevron：固定向下图标，展开时旋转半圈朝上。
class LibraryFilterAccordionChevron extends StatelessWidget {
  const LibraryFilterAccordionChevron({super.key, required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: kLibraryFilterAccordionDuration,
      curve: kLibraryFilterAccordionCurve,
      child: Icon(
        LucideIcons.chevronDown,
        size: 16,
        color: cs.hentai.iconSecondary,
      ),
    );
  }
}
