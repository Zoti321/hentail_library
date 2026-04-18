import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/author.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/common/status/status_card_shell.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/tag_confirm_delete_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/tag_name_editor_dialog.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/button/ghost_button.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/custom_toast.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AuthorManagementPage extends ConsumerWidget {
  const AuthorManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openAddAuthorDialog() async {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => TagNameEditorDialog(
          title: '添加作者',
          labelText: '名称',
          hintText: '输入作者名称…',
          initialValue: '',
          onSubmit: (value) async {
            await ref.read(authorActionsProvider).addAuthor(Author(name: value));
          },
        ),
      );
    }

    final authorsAsync = ref.watch(allAuthorsProvider);
    final String query = ref.watch(authorFilterProvider);

    return _AddShortcutScope(
      onAdd: openAddAuthorDialog,
      child: SingleChildScrollView(
        padding: _AuthorStyles.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorManagementHeader(onAddAuthor: openAddAuthorDialog),
            const SizedBox(height: 20),
            authorsAsync.when(
              data: (authors) {
                final filtered = _applyFilter(authors, query);
                if (filtered.isEmpty) return const _AuthorManagementEmptyState();
                return _AuthorList(authors: filtered);
              },
              loading: () => const _AuthorManagementLoadingCard(),
              error: (e, _) => _AuthorManagementErrorCard(error: e),
            ),
          ],
        ),
      ),
    );
  }

  List<Author> _applyFilter(List<Author> source, String query) {
    if (query.trim().isEmpty) return List<Author>.from(source);
    final q = query.trim().toLowerCase();
    return source.where((a) => a.name.toLowerCase().contains(q)).toList();
  }
}

class _AuthorStyles {
  const _AuthorStyles._();

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 48,
    vertical: 16,
  );

  static const double titleFontSize = 26;
  static const double subtitleFontSize = 13;

  static const double metaChipIconSize = 14;
  static const double metaChipFontSize = 12;
  static const double metaChipRadius = 8;
  static const EdgeInsets metaChipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  static const double listRadius = 12;
  static const EdgeInsets listHeaderPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );
  static const double listHeaderIconSize = 16;
  static const double listHeaderFontSize = 13;

  static const double iconButtonRadius = 8;
  static const Size iconButtonSize = Size(28, 28);

  static const double statusCardRadius = 14;
  static const EdgeInsets statusErrorPadding = EdgeInsets.all(20);
  static const EdgeInsets statusLoadingPadding = EdgeInsets.symmetric(
    vertical: 42,
  );
  static const EdgeInsets statusEmptyPadding = EdgeInsets.symmetric(
    vertical: 48,
  );
}

class _AuthorManagementLoadingCard extends StatelessWidget {
  const _AuthorManagementLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: _AuthorStyles.statusLoadingPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _AuthorManagementErrorCard extends StatelessWidget {
  const _AuthorManagementErrorCard({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StatusCardShell(
      padding: _AuthorStyles.statusErrorPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
      child: Text(
        '$error',
        style: TextStyle(
          fontSize: _AuthorStyles.subtitleFontSize,
          color: theme.colorScheme.textTertiary,
        ),
      ),
    );
  }
}

class _AuthorManagementEmptyState extends StatelessWidget {
  const _AuthorManagementEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return StatusCardShell(
      padding: _AuthorStyles.statusEmptyPadding,
      borderRadius: _AuthorStyles.statusCardRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.penLine, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            '暂无作者',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '你可以从这里添加、重命名或删除作者。',
            style: TextStyle(
              fontSize: _AuthorStyles.subtitleFontSize,
              color: cs.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AuthorManagementHeader extends ConsumerWidget {
  const _AuthorManagementHeader({required this.onAddAuthor});

  final Future<void> Function() onAddAuthor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectionCount = ref.watch(
      authorSelectionProvider.select((Set<Author> s) => s.length),
    );
    final cs = Theme.of(context).colorScheme;
    final String shortcutLabel = _shortcutLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '作者管理',
                style: TextStyle(
                  fontSize: _AuthorStyles.titleFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: cs.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '查看、添加、重命名以及批量删除作者',
                style: TextStyle(
                  color: cs.textTertiary,
                  fontSize: _AuthorStyles.subtitleFontSize,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const _MetaChip(icon: LucideIcons.penLine, label: '作者'),
                  if (selectionCount > 0)
                    _MetaChip(
                      icon: LucideIcons.circleCheckBig,
                      label: '已选 $selectionCount',
                      highlighted: true,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              child: CustomTextField(
                hintText: '搜索作者名称…',
                onChanged: (value) =>
                    ref.read(authorFilterProvider.notifier).setQuery(value),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddAuthor,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text('添加作者 ($shortcutLabel)'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (selectionCount > 0)
              TextButton.icon(
                onPressed: () async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        barrierColor: Colors.transparent,
                        builder: (context) =>
                            TagConfirmDeleteDialog(count: selectionCount),
                      ) ??
                      false;
                  if (!confirmed) return;
                  final authors = ref
                      .read(authorSelectionProvider)
                      .toList(growable: false);
                  await ref.read(authorActionsProvider).deleteAuthors(authors);
                },
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: Text('删除已选'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AddIntent extends Intent {
  const _AddIntent();
}

class _AddShortcutScope extends StatelessWidget {
  const _AddShortcutScope({required this.child, required this.onAdd});

  final Widget child;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyN, control: true): _AddIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true): _AddIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AddIntent: CallbackAction<_AddIntent>(
            onInvoke: (_AddIntent intent) {
              if (_isTextInputFocused()) {
                return null;
              }
              onAdd();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  bool _isTextInputFocused() {
    final FocusNode? node = FocusManager.instance.primaryFocus;
    final BuildContext? context = node?.context;
    if (context == null) {
      return false;
    }
    return context.widget is EditableText;
  }
}

String _shortcutLabel(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;
  final bool isApple =
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  return isApple ? '⌘N' : 'Ctrl+N';
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final bgColor = highlighted
        ? theme.colorScheme.primaryContainer.withAlpha(130)
        : theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: _AuthorStyles.metaChipPadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_AuthorStyles.metaChipRadius),
        border: Border.all(color: theme.colorScheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _AuthorStyles.metaChipIconSize, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: _AuthorStyles.metaChipFontSize,
              fontWeight: FontWeight.w600,
              color: highlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorList extends StatelessWidget {
  const _AuthorList({required this.authors});

  final List<Author> authors;

  @override
  Widget build(BuildContext context) {
    return _AuthorListCard(
      child: Column(
        children: [
          const _AuthorListHeader(),
          _AuthorListView(authors: authors),
        ],
      ),
    );
  }
}

class _AuthorListCard extends StatelessWidget {
  const _AuthorListCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(_AuthorStyles.listRadius),
        border: Border.all(color: cs.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_AuthorStyles.listRadius),
        child: child,
      ),
    );
  }
}

class _AuthorListHeader extends StatelessWidget {
  const _AuthorListHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: _AuthorStyles.listHeaderPadding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.borderSubtle)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.penLine,
            size: _AuthorStyles.listHeaderIconSize,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '全部作者',
            style: TextStyle(
              fontSize: _AuthorStyles.listHeaderFontSize,
              fontWeight: FontWeight.w600,
              color: cs.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorListView extends ConsumerWidget {
  const _AuthorListView({required this.authors});

  final List<Author> authors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: authors.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: cs.borderSubtle),
      itemBuilder: (context, index) {
        final Author author = authors[index];
        final bool isSelected = ref.watch(
          authorSelectionProvider.select((Set<Author> s) => s.contains(author)),
        );
        return _AuthorRow(author: author, isSelected: isSelected);
      },
    );
  }
}

class _AuthorRow extends ConsumerWidget {
  const _AuthorRow({required this.author, required this.isSelected});

  final Author author;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _AuthorRowInteractionShell(
      child: InkWell(
        onTap: () => ref.read(authorSelectionProvider.notifier).toggle(author),
        child: Padding(
          padding: _AuthorStyles.rowPadding,
          child: Row(
            spacing: 12,
            children: [
              GhostButton.icon(
                icon: isSelected
                    ? LucideIcons.squareCheckBig
                    : LucideIcons.square,
                iconSize: 16,
                size: _AuthorStyles.iconButtonSize.width,
                tooltip: isSelected ? '取消选中' : '选中',
                foregroundColor: isSelected ? cs.primary : cs.textTertiary,
                hoverColor: theme.colorScheme.primary.withAlpha(10),
                overlayColor: theme.colorScheme.primary.withAlpha(14),
                borderRadius: 8,
                delayTooltipThreeSeconds: true,
                onPressed: () =>
                    ref.read(authorSelectionProvider.notifier).toggle(author),
              ),

              Expanded(
                child: Text(
                  author.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.textPrimary,
                  ),
                ),
              ),
              GhostButton.icon(
                icon: LucideIcons.squarePen,
                iconSize: 16,
                size: _AuthorStyles.iconButtonSize.width,
                borderRadius: _AuthorStyles.iconButtonRadius,
                tooltip: '重命名',
                delayTooltipThreeSeconds: true,
                hoverColor: cs.primary.withAlpha(10),
                overlayColor: cs.primary.withAlpha(14),
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (context) => TagNameEditorDialog(
                      title: '重命名作者',
                      labelText: '新名称',
                      hintText: '输入新的作者名称…',
                      initialValue: author.name,
                      shouldCloseOnUnchanged: true,
                      onSubmit: (value) async {
                        await ref
                            .read(authorActionsProvider)
                            .renameAuthor(author, value);
                      },
                    ),
                  );
                },
              ),
              GhostButton.icon(
                tooltip: '删除',
                semanticLabel: '删除',
                icon: LucideIcons.trash2,
                iconSize: 16,
                size: _AuthorStyles.iconButtonSize.width,
                borderRadius: _AuthorStyles.iconButtonRadius,
                foregroundColor: cs.error,
                hoverColor: cs.primary.withAlpha(10),
                overlayColor: cs.primary.withAlpha(14),
                delayTooltipThreeSeconds: true,
                onPressed: () async {
                  final bool confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) =>
                            const TagConfirmDeleteDialog(count: 1),
                      ) ??
                      false;
                  if (!confirmed || !context.mounted) {
                    return;
                  }
                  try {
                    await ref.read(authorActionsProvider).deleteAuthor(author);
                    if (context.mounted) {
                      showSuccessToast(context, '已删除作者');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showErrorToast(context, e);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorRowInteractionShell extends StatelessWidget {
  const _AuthorRowInteractionShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: cs.primary.withAlpha(10),
      ),
      child: Material(color: cs.surface, child: child),
    );
  }
}
