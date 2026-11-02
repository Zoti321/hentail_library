import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail_md3e/author_detail_md3e_links.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail_md3e/author_image_view.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _bannerHeight = 140;
const double _avatarSize = 88;

/// 横幅从竖版封面裁横条时偏上保留（人物面部多在上半部）。
const Alignment _bannerAlignment = Alignment(0, -0.4);

/// 作者详情头部：横幅、头像、名称（可改名）与链接。
class AuthorDetailMd3eHeader extends StatelessWidget {
  const AuthorDetailMd3eHeader({super.key, required this.detail});

  final AuthorDetail detail;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AuthorImageRef image = detail.image;
    final String? backgroundComicId =
        image.backgroundComicId ?? image.avatarComicId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipOval(
              child: SizedBox(
                width: _avatarSize,
                height: _avatarSize,
                child: image.showsAuthorImageView(AuthorImageSlot.avatar)
                    ? AuthorImageView(
                        authorId: detail.id,
                        slot: AuthorImageSlot.avatar,
                        comicId: image.avatarComicId,
                        platformImageUrl: image.platformImageUrlFor(
                          AuthorImageSlot.avatar,
                        ),
                      )
                    : ColoredBox(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          LucideIcons.user,
                          size: 36,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _AuthorNameRow(detail: detail),
                  const SizedBox(height: 8),
                  AuthorDetailMd3eLinks(detail: detail),
                ],
              ),
            ),
          ],
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ValueNotifier<bool> editing = useState(false);
    final ObjectRef<bool> busy = useRef(false);
    final TextEditingController controller = useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final TextStyle nameStyle = (textTheme.titleLarge ?? const TextStyle())
        .copyWith(fontWeight: FontWeight.w700, color: cs.onSurface);

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
      );
    }

    final List<String> aliases = authorAliases(
      authorName: detail.name,
      links: detail.links,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (detail.verified) ...<Widget>[
          Tooltip(
            message: l10n.authorDetailVerified,
            child: Icon(LucideIcons.badgeCheck, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
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
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.authorDetailRename,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          color: cs.onSurfaceVariant,
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
