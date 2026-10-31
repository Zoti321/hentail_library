import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/author_detail_md3e/author_detail_md3e_body.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/sheets/md3e_overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 作者详情侧边 sheet 宽度（expanded+）。
const double _authorSideSheetWidth = 480;

/// 打开作者详情（MD3E）：compact / medium 为全屏底部 sheet，expanded+ 为侧边 sheet。
Future<void> showAuthorDetailMd3e({
  required BuildContext context,
  required int authorId,
}) {
  final double viewportWidth = MediaQuery.sizeOf(context).width;
  final String title = AppLocalizations.of(context).authorDetailTitle;
  final Md3eOverlayRouteScopeSnapshot scope =
      Md3eOverlayRouteScopeSnapshot.capture(context);
  final M3EThemeData m3e = md3eWithAppFontFamily(M3ETheme.of(context));
  final Widget content = md3eOverlayRouteScope(
    scope: scope,
    child: M3ETheme(
      data: m3e,
      child: AuthorDetailMd3eBody(authorId: authorId),
    ),
  );

  if (viewportWidth < Md3eBreakpoints.expanded) {
    // 底部 sheet 的全屏标题由包内 header 读取自身上下文主题，无法注入应用字体；
    // 因此在 body 内用已带应用字体的主题绘制标题。
    final Widget sheetBody = M3ETheme(
      data: m3e,
      child: Builder(
        builder: (BuildContext themed) {
          final M3EThemeData theme = M3ETheme.of(themed);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typeScale.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              content,
            ],
          );
        },
      ),
    );
    return M3EBottomSheet.show<void>(
      context,
      useRootNavigator: true,
      expandToFullScreen: true,
      theme: M3ETheme.of(context).bottomSheetTheme,
      builder: (BuildContext sheetContext) {
        return PrimaryScrollController.none(
          child: SingleChildScrollView(child: sheetBody),
        );
      },
    );
  }

  return M3ESideSheet.show<void>(
    context,
    title: title,
    width: _authorSideSheetWidth,
    detached: Md3eWindowSizeClass.fromWidth(viewportWidth).isAtLeastExpanded,
    // 侧栏标题由 sheet 自身上下文读取主题，需显式指定应用字体。
    theme: M3ETheme.of(context).sideSheetTheme.copyWith(
      horizontalPadding: 16,
      topElementsGap: 8,
      headlineTextStyle: const TextStyle(fontFamily: kMd3eAppFontFamily),
    ),
    scrollable: true,
    useRootNavigator: true,
    body: content,
  );
}

/// 按作者名打开作者详情；名称不存在时静默忽略。
Future<void> showAuthorDetailMd3eByName({
  required BuildContext context,
  required WidgetRef ref,
  required String name,
}) async {
  final int? authorId = await ref
      .read(authorDetailCommandsProvider)
      .idByName(name);
  if (authorId == null || !context.mounted) {
    return;
  }
  await showAuthorDetailMd3e(context: context, authorId: authorId);
}
