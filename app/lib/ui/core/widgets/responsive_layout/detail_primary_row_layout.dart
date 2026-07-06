import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// 详情页封面 + 主信息区：窄屏单列、宽屏横排。
class DetailPrimaryRowLayout extends StatelessWidget {
  const DetailPrimaryRowLayout({
    super.key,
    required this.cover,
    required this.content,
    this.coverWidth = 220,
    this.narrowBreakpoint = AppLayoutBreakpoints.compact,
  });

  final Widget cover;
  final Widget content;
  final double coverWidth;
  final double narrowBreakpoint;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < narrowBreakpoint;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: SizedBox(width: coverWidth, child: cover),
              ),
              SizedBox(height: tokens.spacing.lg),
              content,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: coverWidth, child: cover),
            SizedBox(width: tokens.spacing.xl),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

/// 详情页水平内边距：窄屏收紧，宽屏沿用 content area。
double detailContentHorizontalPadding(BuildContext context) {
  final AppThemeTokens tokens = context.tokens;
  final double width = MediaQuery.sizeOf(context).width;
  if (width < AppLayoutBreakpoints.compact) {
    return tokens.spacing.lg;
  }
  return tokens.layout.contentHorizontalPadding;
}
