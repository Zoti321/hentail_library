import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/tag_name_editor_dialog.dart';
import 'package:hentai_library/ui/features/library/view_models/author_detail_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final AuthorDetail? detail = asyncDetail.asData?.value;
    return AdaptiveFormSurface(
      title: detail?.name ?? l10n.authorDetailTitle,
      maxDialogWidth: 520,
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
        OutlinedButton(
          onPressed: detail == null
              ? null
              : () => _rename(context, ref, detail),
          child: Text(l10n.authorDetailRename),
        ),
        FilledButton(
          onPressed: detail == null
              ? null
              : () => _openSearch(context, detail.name),
          child: Text(l10n.authorDetailViewInSearch),
        ),
      ],
    );
  }
}

Future<void> _openSearch(BuildContext context, String name) async {
  final String query = formatLibrarySearchExactMetaQuery(name);
  final String encoded = Uri.encodeQueryComponent(query);
  Navigator.of(context).maybePop();
  appRouter.push('/searched?q=$encoded');
}

Future<void> _rename(
  BuildContext context,
  WidgetRef ref,
  AuthorDetail detail,
) async {
  final l10n = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => TagNameEditorDialog(
      title: l10n.authorDetailRename,
      labelText: l10n.metadataNameLabel,
      hintText: l10n.metadataRenameAuthorHint,
      initialValue: detail.name,
      shouldCloseOnUnchanged: true,
      onSubmit: (String value) async {
        await ref
            .read(authorDetailCommandsProvider)
            .rename(authorId: detail.id, oldName: detail.name, newName: value);
      },
    ),
  );
}

class _AuthorDetailBody extends ConsumerWidget {
  const _AuthorDetailBody({required this.detail});

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

  Future<void> _editLink(
    BuildContext context,
    WidgetRef ref, {
    AuthorLink? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _AuthorLinkEditorDialog(
        initial: existing,
        onSubmit:
            (
              AuthorLinkPlatform platform,
              String url,
              String? displayName,
            ) async {
              final AuthorDetailCommands commands = ref.read(
                authorDetailCommandsProvider,
              );
              if (existing == null) {
                await commands.addLink(
                  authorId: detail.id,
                  platform: platform,
                  url: url,
                  platformDisplayName: displayName,
                );
              } else {
                await commands.updateLink(
                  authorId: detail.id,
                  linkId: existing.id,
                  platform: platform,
                  url: url,
                  platformDisplayName: displayName,
                );
              }
            },
        onDelete: existing == null
            ? null
            : () async {
                await ref
                    .read(authorDetailCommandsProvider)
                    .deleteLink(authorId: detail.id, linkId: existing.id);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final String? coverId = detail.image.avatarComicId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 120,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (coverId != null)
                Opacity(
                  opacity: 0.35,
                  child: ComicCoverContent(comicId: coverId),
                )
              else
                ColoredBox(color: cs.surfaceContainerHighest),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(tokens.spacing.sm),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipOval(
                          child: coverId == null
                              ? ColoredBox(
                                  color: cs.surface,
                                  child: Icon(
                                    LucideIcons.user,
                                    color: cs.hentai.iconSecondary,
                                  ),
                                )
                              : ComicCoverContent(comicId: coverId),
                        ),
                      ),
                      SizedBox(width: tokens.spacing.sm),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                detail.name,
                                style: TextStyle(
                                  fontSize: tokens.text.titleMd,
                                  fontWeight: FontWeight.w600,
                                  color: cs.hentai.textPrimary,
                                ),
                              ),
                            ),
                            if (detail.verified) ...<Widget>[
                              SizedBox(width: tokens.spacing.xs),
                              Semantics(
                                label: l10n.authorDetailVerified,
                                child: Icon(
                                  LucideIcons.badgeCheck,
                                  size: 18,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.md),
        Wrap(
          spacing: tokens.spacing.sm,
          runSpacing: tokens.spacing.sm,
          children: <Widget>[
            for (final AuthorLink link in detail.links)
              OutlinedMetaChip(
                text: _linkChipLabel(l10n, link),
                compact: true,
                icon: LucideIcons.link,
                onTap: () => _openLink(context, link.url),
                onLongPress: () => _editLink(context, ref, existing: link),
              ),
            OutlinedMetaChip(
              text: l10n.authorDetailAddLink,
              compact: true,
              onTap: () => _editLink(context, ref),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.lg),
        _FacetSection(
          title: l10n.authorDetailParodiesSection,
          empty: l10n.authorDetailParodiesEmpty,
          items: detail.parodies,
          onChipTap: (String name) => _openSearch(context, name),
        ),
        _FacetSection(
          title: l10n.authorDetailCharactersSection,
          empty: l10n.authorDetailCharactersEmpty,
          items: detail.characters,
          onChipTap: (String name) => _openSearch(context, name),
        ),
        _FacetSection(
          title: l10n.authorDetailTagsSection,
          empty: l10n.authorDetailTagsEmpty,
          items: detail.tags,
          onChipTap: (String name) => _openSearch(context, name),
        ),
        Text(
          l10n.authorDetailComicsSection,
          style: TextStyle(
            fontSize: tokens.text.titleSm,
            fontWeight: FontWeight.w600,
            color: cs.hentai.textPrimary,
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        if (detail.topComics.isEmpty)
          Text(
            l10n.authorDetailComicsEmpty,
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.hentai.textSecondary,
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.topComics.length,
              separatorBuilder: (BuildContext context, int index) =>
                  SizedBox(width: tokens.spacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final AuthorTopComic comic = detail.topComics[index];
                return SizedBox(
                  width: 90,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).maybePop();
                      appRouter.push(
                        '/comic/${Uri.encodeComponent(comic.comicId)}',
                      );
                    },
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ComicCoverContent(comicId: comic.comicId),
                        ),
                        SizedBox(height: tokens.spacing.xs),
                        Text(
                          comic.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: tokens.text.labelXs),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FacetSection extends StatelessWidget {
  const _FacetSection({
    required this.title,
    required this.empty,
    required this.items,
    required this.onChipTap,
  });

  final String title;
  final String empty;
  final List<AuthorFacetCount> items;
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: tokens.text.titleSm,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textPrimary,
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          if (items.isEmpty)
            Text(
              empty,
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.hentai.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: tokens.spacing.sm,
              runSpacing: tokens.spacing.sm,
              children: items
                  .map(
                    (AuthorFacetCount item) => OutlinedMetaChip(
                      text: '${item.name} ${item.attachmentCount}',
                      compact: true,
                      onTap: () => onChipTap(item.name),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
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
  }
  return _platformLabel(l10n, link.platform);
}

class _AuthorLinkEditorDialog extends StatefulWidget {
  const _AuthorLinkEditorDialog({
    required this.onSubmit,
    this.initial,
    this.onDelete,
  });

  final AuthorLink? initial;
  final Future<void> Function(
    AuthorLinkPlatform platform,
    String url,
    String? displayName,
  )
  onSubmit;
  final Future<void> Function()? onDelete;

  @override
  State<_AuthorLinkEditorDialog> createState() =>
      _AuthorLinkEditorDialogState();
}

class _AuthorLinkEditorDialogState extends State<_AuthorLinkEditorDialog> {
  late AuthorLinkPlatform _platform =
      widget.initial?.platform ?? AuthorLinkPlatform.pixiv;
  late final TextEditingController _url = TextEditingController(
    text: widget.initial?.url ?? '',
  );
  late final TextEditingController _otherName = TextEditingController(
    text: widget.initial?.platformDisplayName ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _url.dispose();
    _otherName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String url = _url.text.trim();
    final String lower = url.toLowerCase();
    if (url.isEmpty ||
        !(lower.startsWith('http://') || lower.startsWith('https://'))) {
      showErrorToast(context, context.l10n.authorDetailInvalidUrl);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        _platform,
        url,
        _platform == AuthorLinkPlatform.other ? _otherName.text.trim() : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showErrorToast(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final Future<void> Function()? onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await onDelete();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showErrorToast(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HentaiDialog(
      title: widget.initial == null
          ? l10n.authorDetailAddLink
          : l10n.authorDetailEditLink,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DropdownButton<AuthorLinkPlatform>(
            value: _platform,
            isExpanded: true,
            items: AuthorLinkPlatform.values
                .map(
                  (AuthorLinkPlatform p) => DropdownMenuItem(
                    value: p,
                    child: Text(_platformLabel(l10n, p)),
                  ),
                )
                .toList(),
            onChanged: (AuthorLinkPlatform? value) {
              if (value != null) {
                setState(() => _platform = value);
              }
            },
          ),
          if (_platform == AuthorLinkPlatform.other)
            TextField(
              controller: _otherName,
              decoration: InputDecoration(
                labelText: l10n.authorDetailPlatformOtherName,
              ),
            ),
          TextField(
            controller: _url,
            decoration: InputDecoration(
              labelText: l10n.authorDetailLinkUrl,
              hintText: l10n.authorDetailLinkUrlHint,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        if (widget.onDelete != null)
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(l10n.authorDetailDeleteLink),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
