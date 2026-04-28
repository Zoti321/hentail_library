import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/entity/reading_history.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/shared/routing/app_router.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/overlays/dialog/edit_metadata_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

ButtonStyle comicDetailPrimaryActionStyle(
  ThemeData theme,
  AppThemeTokens tokens,
) {
  final ColorScheme cs = theme.colorScheme;
  return ElevatedButton.styleFrom(
    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
    elevation: 1,
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.xl,
      vertical: tokens.spacing.sm + 6,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.md),
    ),
  );
}

class ComicDetailPrimaryActions extends HookConsumerWidget {
  const ComicDetailPrimaryActions({super.key, required this.comic});
  final Comic comic;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ButtonStyle primaryStyle = comicDetailPrimaryActionStyle(
      theme,
      tokens,
    );
    return Wrap(
      spacing: tokens.spacing.md,
      runSpacing: tokens.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Semantics(
          label: '开始阅读',
          button: true,
          child: ElevatedButton.icon(
            onPressed: () async {
              await ref
                  .read(recordReadingProgressUseCaseProvider)
                  .call(
                    ReadingHistory(
                      comicId: comic.comicId,
                      title: comic.title,
                      lastReadTime: DateTime.now(),
                    ),
                  );
              appRouter.pushNamed(
                ReaderRouteArgs.readerRouteName,
                queryParameters: ReaderRouteArgs(
                  comicId: comic.comicId,
                  readType: ReaderRouteArgs.readTypeComic,
                ).toQueryParameters(),
              );
            },
            icon: Icon(LucideIcons.play, size: 16),
            label: const Text('开始阅读'),
            style: primaryStyle,
          ),
        ),
        Semantics(
          label: '编辑元数据',
          button: true,
          child: GhostButton.icon(
            icon: LucideIcons.pencil,
            tooltip: '编辑元数据',
            semanticLabel: '编辑元数据',
            size: 32,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => EditMetadataDialog(
                  comic: comic,
                  onSave: (data) async {
                    await ref.read(updateComicMetadataUseCaseProvider)(
                      comic.comicId,
                      data,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
