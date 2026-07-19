import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
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
      borderRadius: BorderRadius.circular(tokens.radius.xs),
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
      borderRadius: BorderRadius.circular(tokens.radius.xs),
      side: BorderSide(color: cs.hentai.borderSubtle),
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
    final ButtonStyle incognitoStyle = comicDetailIncognitoReadStyle(
      theme,
      tokens,
    );
    final AppLocalizations l10n = context.l10n;
    return Wrap(
      spacing: tokens.spacing.md,
      runSpacing: tokens.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Semantics(
          label: l10n.comicDetailRead,
          button: true,
          child: ElevatedButton.icon(
            onPressed: () => _openReader(ref, incognito: false),
            icon: const Icon(LucideIcons.bookOpen, size: 16),
            label: Text(l10n.comicDetailRead),
            style: primaryStyle,
          ),
        ),
        Semantics(
          label: l10n.comicDetailReadIncognito,
          button: true,
          child: ElevatedButton.icon(
            onPressed: () => _openReader(ref, incognito: true),
            icon: const Icon(LucideIcons.hatGlasses, size: 16),
            label: Text(l10n.comicDetailRead),
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
