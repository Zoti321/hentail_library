import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
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

ButtonStyle comicDetailSecondaryActionStyle(
  ThemeData theme,
  AppThemeTokens tokens,
) {
  final ColorScheme cs = theme.colorScheme;
  return OutlinedButton.styleFrom(
    foregroundColor: cs.hentai.textSecondary,
    disabledForegroundColor: cs.hentai.textTertiary,
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.xl,
      vertical: tokens.spacing.sm + 6,
    ),
    side: BorderSide(color: cs.hentai.borderSubtle),
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
    final ButtonStyle secondaryStyle = comicDetailSecondaryActionStyle(
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
                  .read(readingHistoryRepoProvider)
                  .recordReading(
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
            icon: const Icon(LucideIcons.play, size: 16),
            label: const Text('开始阅读'),
            style: primaryStyle,
          ),
        ),
        Semantics(
          label: '无痕阅读',
          button: true,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(LucideIcons.eyeOff, size: 16),
            label: const Text('无痕阅读'),
            style: secondaryStyle,
          ),
        ),
      ],
    );
  }
}
