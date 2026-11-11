import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

/// 链接 chip 列表 + 「添加链接」；添加时原位变为输入框，平台按 URL 自动识别。
class AuthorDetailLinks extends HookConsumerWidget {
  const AuthorDetailLinks({super.key, required this.detail});

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
      showErrorSnackbar(context, context.l10n.authorDetailOpenLinkFailed);
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
        showErrorSnackbar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
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
        showErrorSnackbar(context, l10n.authorDetailInvalidUrl);
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
          showErrorSnackbar(context, error);
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
      spacing: 8,
      runSpacing: 8,
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
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Symbols.link, size: 16),
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
          M3EButton.icon(
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
            onPressed: () => adding.value = true,
            icon: Icon(Symbols.add, size: 18),
            label: Text(l10n.authorDetailAddLink),
          ),
      ],
    );
  }
}

IconData _platformIcon(AuthorLinkPlatform platform) {
  return switch (platform) {
    AuthorLinkPlatform.pixiv => LucideIcons.palette,
    AuthorLinkPlatform.x => LucideIcons.x,
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
