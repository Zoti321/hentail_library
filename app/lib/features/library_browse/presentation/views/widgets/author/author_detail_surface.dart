import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_search_query_parser.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/author/author_image_view.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

const double _bannerHeight = 140;

/// 横幅从竖版封面裁横条时偏上保留（人物面部多在上半部）。
const Alignment _bannerAlignment = Alignment(0, -0.4);
const double _avatarSize = 88;
const double _avatarRing = 4;
const double _comicCardWidth = 96;
const double _comicCardHeight = 144;

class AuthorDetailSurface extends ConsumerWidget {
  const AuthorDetailSurface({super.key, required this.authorId});

  final int authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<AuthorDetail?> asyncDetail = ref.watch(
      authorDetailProvider(authorId),
    );
    return AdaptiveFormSurface(
      title: l10n.authorDetailTitle,
      maxDialogWidth: 560,
      borderRadius: tokens.radius.xs,
      fitContentHeight: false,
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Text('$error'),
        data: (AuthorDetail? value) {
          if (value == null) {
            return Text(l10n.comicDetailNotFound);
          }
          return _AuthorDetailBody(detail: value);
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

void _openSearch(BuildContext context, Iterable<String> names) {
  final String query = formatLibrarySearchAndExactMetaQuery(names);
  final String encoded = Uri.encodeQueryComponent(query);
  Navigator.of(context).maybePop();
  appRouter.push('/searched?q=$encoded');
}

class _AuthorDetailBody extends StatelessWidget {
  const _AuthorDetailBody({required this.detail});

  final AuthorDetail detail;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _AuthorHeader(detail: detail),
        SizedBox(height: tokens.spacing.lg),
        _AuthorComicsSection(detail: detail),
      ],
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({required this.detail});

  final AuthorDetail detail;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AuthorImageRef image = detail.image;
    final String? backgroundComicId =
        image.backgroundComicId ?? image.avatarComicId;
    final String? avatarComicId = image.avatarComicId;
    final double avatarLeft = tokens.spacing.md;
    const double avatarOuter = _avatarSize + _avatarRing * 2;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radius.md),
              child: SizedBox(
                height: _bannerHeight,
                child: image.showsAuthorImageView(AuthorImageSlot.background)
                    ? AuthorImageView(
                        authorId: detail.id,
                        slot: AuthorImageSlot.background,
                        comicId: backgroundComicId,
                        platformImageUrl: image.platformImageUrlFor(
                          AuthorImageSlot.background,
                        ),
                        alignment: _bannerAlignment,
                      )
                    : ColoredBox(color: cs.surfaceContainerHighest),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: avatarOuter / 2 + 4),
              child: Padding(
                padding: EdgeInsets.only(
                  left: avatarLeft + avatarOuter + tokens.spacing.md,
                  top: tokens.spacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _AuthorNameRow(detail: detail),
                    SizedBox(height: tokens.spacing.xs),
                    _AuthorLinksWrap(detail: detail),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: avatarLeft,
          top: _bannerHeight - avatarOuter / 2,
          child: Container(
            width: avatarOuter,
            height: avatarOuter,
            padding: const EdgeInsets.all(_avatarRing),
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: image.showsAuthorImageView(AuthorImageSlot.avatar)
                  ? AuthorImageView(
                      authorId: detail.id,
                      slot: AuthorImageSlot.avatar,
                      comicId: avatarComicId,
                      platformImageUrl: image.platformImageUrlFor(
                        AuthorImageSlot.avatar,
                      ),
                    )
                  : ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        LucideIcons.user,
                        size: 36,
                        color: cs.hentai.iconSecondary,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 作者名 + 铅笔按钮；点击后原位变为输入框（Enter / 失焦提交，Esc 取消）。
class _AuthorNameRow extends HookConsumerWidget {
  const _AuthorNameRow({required this.detail});

  final AuthorDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ValueNotifier<bool> editing = useState(false);
    final ObjectRef<bool> busy = useRef(false);
    final TextEditingController controller = useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final TextStyle nameStyle = TextStyle(
      fontSize: tokens.text.titleLg,
      fontWeight: FontWeight.w700,
      color: cs.hentai.textPrimary,
    );

    Future<void> submit() async {
      if (!editing.value || busy.value) {
        return;
      }
      final String value = controller.text.trim();
      if (value.isEmpty || value == detail.name) {
        editing.value = false;
        return;
      }
      busy.value = true;
      try {
        await ref
            .read(authorDetailCommandsProvider)
            .rename(authorId: detail.id, oldName: detail.name, newName: value);
        if (context.mounted) {
          editing.value = false;
        }
      } catch (error) {
        if (context.mounted) {
          showErrorToast(context, error);
          editing.value = false;
        }
      } finally {
        busy.value = false;
      }
    }

    useEffect(() {
      void onFocusChange() {
        if (!focusNode.hasFocus) {
          submit();
        }
      }

      focusNode.addListener(onFocusChange);
      return () => focusNode.removeListener(onFocusChange);
    }, <Object?>[focusNode, detail.name]);

    if (editing.value) {
      return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              editing.value = false,
        },
        child: SizedBox(
          width: 260,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            style: nameStyle,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.metadataRenameAuthorHint,
            ),
            onSubmitted: (_) => submit(),
          ),
        ),
      );
    }

    final List<String> aliases = authorAliases(
      authorName: detail.name,
      links: detail.links,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (detail.verified) ...<Widget>[
          Tooltip(
            message: l10n.authorDetailVerified,
            child: Icon(LucideIcons.badgeCheck, size: 20, color: cs.primary),
          ),
          SizedBox(width: tokens.spacing.xs),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                detail.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nameStyle,
              ),
              if (aliases.isNotEmpty)
                Text(
                  l10n.authorDetailAliases(aliases.join(', ')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    color: cs.hentai.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: tokens.spacing.xs),
        IconButton(
          tooltip: l10n.authorDetailRename,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          color: cs.hentai.iconSecondary,
          onPressed: () {
            controller.text = detail.name;
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: detail.name.length,
            );
            editing.value = true;
          },
          icon: const Icon(LucideIcons.pencil),
        ),
      ],
    );
  }
}

/// 链接 chip 列表 + 「添加链接」；添加时原位变为输入框，平台按 URL 自动识别。
class _AuthorLinksWrap extends HookConsumerWidget {
  const _AuthorLinksWrap({required this.detail});

  final AuthorDetail detail;

  Future<void> _openLink(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) {
        throw StateError('cannot launch');
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      showErrorToast(context, context.l10n.authorDetailOpenLinkFailed);
    }
  }

  Future<void> _deleteLink(
    BuildContext context,
    WidgetRef ref,
    AuthorLink link,
  ) async {
    try {
      await ref
          .read(authorDetailCommandsProvider)
          .deleteLink(authorId: detail.id, linkId: link.id);
    } catch (error) {
      if (context.mounted) {
        showErrorToast(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ValueNotifier<bool> adding = useState(false);
    final ObjectRef<bool> busy = useRef(false);
    final TextEditingController controller = useTextEditingController();
    final FocusNode focusNode = useFocusNode();

    Future<void> submit() async {
      if (!adding.value || busy.value) {
        return;
      }
      final String url = controller.text.trim();
      if (url.isEmpty) {
        adding.value = false;
        return;
      }
      final String lower = url.toLowerCase();
      if (!(lower.startsWith('http://') || lower.startsWith('https://'))) {
        showErrorToast(context, l10n.authorDetailInvalidUrl);
        return;
      }
      busy.value = true;
      try {
        await ref
            .read(authorDetailCommandsProvider)
            .addLink(
              authorId: detail.id,
              platform: detectAuthorLinkPlatform(url),
              url: url,
            );
        if (context.mounted) {
          controller.clear();
          adding.value = false;
        }
      } catch (error) {
        if (context.mounted) {
          showErrorToast(context, error);
        }
      } finally {
        busy.value = false;
      }
    }

    useEffect(() {
      void onFocusChange() {
        if (!focusNode.hasFocus && controller.text.trim().isEmpty) {
          adding.value = false;
        }
      }

      focusNode.addListener(onFocusChange);
      return () => focusNode.removeListener(onFocusChange);
    }, <Object?>[focusNode]);

    return Wrap(
      spacing: tokens.spacing.md,
      runSpacing: tokens.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final AuthorLink link in detail.links)
          Tooltip(
            message: l10n.authorDetailLinkTooltip(link.url),
            waitDuration: const Duration(milliseconds: 500),
            child: OutlinedMetaChip(
              text: _linkChipLabel(l10n, link),
              compact: true,
              showBorder: false,
              textColor: cs.primary,
              icon: _platformIcon(link.platform),
              onTap: () => _openLink(context, link.url),
              onRemove: () => _deleteLink(context, ref, link),
              removeTooltip: l10n.authorDetailDeleteLink,
              removeOnDesktopHoverOnly: true,
            ),
          ),
        if (adding.value)
          CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.escape): () {
                controller.clear();
                adding.value = false;
              },
            },
            child: SizedBox(
              width: 260,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.url,
                style: TextStyle(fontSize: tokens.text.bodySm),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(LucideIcons.link, size: 14),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 20,
                  ),
                  hintText: l10n.authorDetailLinkPasteHint,
                ),
                onSubmitted: (_) => submit(),
              ),
            ),
          )
        else
          OutlinedMetaChip(
            text: l10n.authorDetailAddLink,
            compact: true,
            icon: LucideIcons.plus,
            onTap: () => adding.value = true,
          ),
      ],
    );
  }
}

class _AuthorComicsSection extends StatelessWidget {
  const _AuthorComicsSection({required this.detail});

  final AuthorDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<AuthorFacetCount> facets = <AuthorFacetCount>[
      ...detail.parodies,
      ...detail.characters,
      ...detail.tags,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.authorDetailComicsSection(detail.comicCount),
                style: TextStyle(
                  fontSize: tokens.text.titleSm,
                  fontWeight: FontWeight.w600,
                  color: cs.hentai.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openSearch(context, <String>[detail.name]),
              icon: const Icon(LucideIcons.search, size: 14),
              label: Text(l10n.authorDetailViewInSearch),
            ),
          ],
        ),
        if (facets.isNotEmpty) ...<Widget>[
          SizedBox(height: tokens.spacing.sm),
          Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: <Widget>[
              for (final AuthorFacetCount item in facets)
                OutlinedMetaChip(
                  text: '${item.name} ${item.attachmentCount}',
                  compact: true,
                  onTap: () =>
                      _openSearch(context, <String>[item.name, detail.name]),
                ),
            ],
          ),
        ],
        SizedBox(height: tokens.spacing.md),
        if (detail.topComics.isEmpty)
          Text(
            l10n.authorDetailComicsEmpty,
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.hentai.textSecondary,
            ),
          )
        else
          Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: <Widget>[
              for (final AuthorTopComic comic in detail.topComics)
                _AuthorComicCoverCard(comic: comic),
            ],
          ),
      ],
    );
  }
}

class _AuthorComicCoverCard extends StatelessWidget {
  const _AuthorComicCoverCard({required this.comic});

  final AuthorTopComic comic;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final BorderRadius radius = BorderRadius.circular(tokens.radius.sm);
    return Tooltip(
      message: comic.title,
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        button: true,
        label: comic.title,
        child: SizedBox(
          width: _comicCardWidth,
          height: _comicCardHeight,
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).maybePop();
                  appRouter.push(
                    '/comic/${Uri.encodeComponent(comic.comicId)}',
                  );
                },
                child: ComicCoverContent(comicId: comic.comicId),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _platformIcon(AuthorLinkPlatform platform) {
  return switch (platform) {
    AuthorLinkPlatform.pixiv => LucideIcons.palette,
    AuthorLinkPlatform.x => LucideIcons.twitter,
    AuthorLinkPlatform.patreon => LucideIcons.heart,
    AuthorLinkPlatform.fanbox => LucideIcons.brush,
    AuthorLinkPlatform.discord => LucideIcons.messageCircle,
    AuthorLinkPlatform.other => LucideIcons.globe,
  };
}

String _platformLabel(AppLocalizations l10n, AuthorLinkPlatform platform) {
  return switch (platform) {
    AuthorLinkPlatform.pixiv => l10n.authorDetailPlatformPixiv,
    AuthorLinkPlatform.x => l10n.authorDetailPlatformX,
    AuthorLinkPlatform.patreon => l10n.authorDetailPlatformPatreon,
    AuthorLinkPlatform.fanbox => l10n.authorDetailPlatformFanbox,
    AuthorLinkPlatform.discord => l10n.authorDetailPlatformDiscord,
    AuthorLinkPlatform.other => l10n.authorDetailPlatformOther,
  };
}

String _linkChipLabel(AppLocalizations l10n, AuthorLink link) {
  if (link.platform == AuthorLinkPlatform.other) {
    final String? custom = link.platformDisplayName?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    final String host = Uri.tryParse(link.url)?.host ?? '';
    if (host.isNotEmpty) {
      return host.startsWith('www.') ? host.substring(4) : host;
    }
  }
  return _platformLabel(l10n, link.platform);
}
