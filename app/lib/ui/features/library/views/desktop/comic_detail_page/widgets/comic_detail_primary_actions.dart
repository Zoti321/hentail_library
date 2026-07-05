import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/widgets/icons/incognito_read_icon.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/reader/read_session_launcher.dart';
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

ButtonStyle comicDetailIncognitoReadStyle(
  ThemeData theme,
  AppThemeTokens tokens,
) {
  final ColorScheme cs = theme.colorScheme;
  return ElevatedButton.styleFrom(
    backgroundColor: cs.surfaceContainerHigh,
    foregroundColor: cs.hentai.textPrimary,
    elevation: 1,
    shadowColor: cs.hentai.cardShadow,
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
    final ColorScheme cs = theme.colorScheme;
    final ButtonStyle primaryStyle = comicDetailPrimaryActionStyle(
      theme,
      tokens,
    );
    final ButtonStyle incognitoStyle = comicDetailIncognitoReadStyle(
      theme,
      tokens,
    );
    return Wrap(
      spacing: tokens.spacing.md,
      runSpacing: tokens.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Semantics(
          label: '阅读',
          button: true,
          child: ElevatedButton.icon(
            onPressed: () => _openReader(ref, incognito: false),
            icon: const Icon(LucideIcons.bookOpen, size: 16),
            label: const Text('阅读'),
            style: primaryStyle,
          ),
        ),
        Semantics(
          label: '无痕阅读',
          button: true,
          child: ElevatedButton.icon(
            onPressed: () => _openReader(ref, incognito: true),
            icon: IncognitoReadIcon(size: 16, color: cs.hentai.textPrimary),
            label: const Text('阅读'),
            style: incognitoStyle,
          ),
        ),
      ],
    );
  }

  Future<void> _openReader(WidgetRef ref, {required bool incognito}) async {
    await openComicReadSession(ref, comic: comic, incognito: incognito);
  }
}
