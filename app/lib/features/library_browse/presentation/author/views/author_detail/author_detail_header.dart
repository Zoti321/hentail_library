import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail/author_detail_links.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail/author_image_view.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';
import 'package:hentai_library/shared/ui/widgets/settings/tonal_surface.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

const double _bannerHeight = 152;
const double _avatarSize = 96;
const double _avatarRingWidth = 4;

/// 横幅从竖版封面裁横条时偏上保留（人物面部多在上半部）。
const Alignment _bannerAlignment = Alignment(0, -0.4);

/// 作者详情头部：tonal 英雄卡（横幅 + 重叠头像、名称与链接）。
class AuthorDetailHeader extends StatelessWidget {
  const AuthorDetailHeader({super.key, required this.detail});

  final AuthorDetail detail;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme cs = theme.colorScheme;
    final AuthorImageRef image = detail.image;
    final String? backgroundComicId =
        image.backgroundComicId ?? image.avatarComicId;
    final double avatarOverlap = _avatarSize / 2;

    return TonalSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              SizedBox(
                height: _bannerHeight,
                width: double.infinity,
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
              Positioned(
                left: theme.spacing.xl,
                bottom: -avatarOverlap,
                child: _AuthorAvatarRing(
                  ringColor: cs.surfaceContainerLow,
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
                              Symbols.person,
                              size: 40,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: avatarOverlap + theme.spacing.md),
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.xl,
              0,
              theme.spacing.xl,
              theme.spacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _AuthorNameRow(detail: detail),
                SizedBox(height: theme.spacing.sm),
                AuthorDetailLinks(detail: detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorAvatarRing extends StatelessWidget {
  const _AuthorAvatarRing({required this.ringColor, required this.child});

  final Color ringColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: _avatarRingWidth),
      ),
      child: ClipOval(child: child),
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
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme cs = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final ValueNotifier<bool> editing = useState(false);
    final ObjectRef<bool> busy = useRef(false);
    final TextEditingController controller = useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final TextStyle nameStyle = type.headlineSmall.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
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
          showErrorSnackbar(context, error);
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
            child: Icon(Symbols.verified, size: 22, color: cs.primary),
          ),
          SizedBox(width: theme.spacing.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                detail.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: nameStyle,
              ),
              if (aliases.isNotEmpty)
                Text(
                  l10n.authorDetailAliases(aliases.join(', ')),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
        M3EIconButton(
          icon: Icon(Symbols.edit, size: 18, color: cs.onSurfaceVariant),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.sm,
          tooltip: l10n.authorDetailRename,
          semanticLabel: l10n.authorDetailRename,
          onPressed: () {
            controller.text = detail.name;
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: detail.name.length,
            );
            editing.value = true;
          },
        ),
      ],
    );
  }
}
