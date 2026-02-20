import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';
import 'package:hentai_library/presentation/widgets/card_item/reading_history_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const .symmetric(horizontal: 24, vertical: 36),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 16,
        children: [const _Header(), const _HistoryList()],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final rawData = ref.watch(readingHistoryStreamProvider);

    final history = rawData.when(
      data: (data) => data,
      loading: () => <ReadingHistory>[],
      error: (error, _) => <ReadingHistory>[],
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );

    return Container(
      padding: const .all(2),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: .start,
            spacing: 6,
            children: [
              Row(
                spacing: 4,
                children: [
                  Icon(
                    LucideIcons.history,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    "阅读历史",
                    style: TextStyle(
                      color: theme.colorScheme.textPrimary,
                      fontSize: 24,
                      fontWeight: .w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Text(
                "${history.length} 条记录 • 最长保留 30 天",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: .w200,
                  color: theme.colorScheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: CustomTextField(hintText: "搜索历史记录..."),
          ),
          const SizedBox(width: 12),
          _buildClearBtn(),
        ],
      ),
    );
  }

  Widget _buildClearBtn() {
    return Tooltip(
      message: '清空阅读历史',
      child: Semantics(
        label: '清空阅读历史',
        button: true,
        child: TextButton.icon(
          onPressed: () {},
          icon: Icon(LucideIcons.trash2, size: 16),
          label: const Text(
            '清空',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.hovered)) {
            return Colors.red.shade700;
          }
          return Colors.red.shade600;
        }),
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.hovered)) {
            return Colors.red.shade50;
          }
          return Colors.transparent;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        padding: WidgetStateProperty.all(
          const .symmetric(horizontal: 12, vertical: 8),
        ),
        overlayColor: MaterialStateProperty.all(Colors.red.withOpacity(0.08)),
      ),
    ),
    ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rawData = ref.watch(readingHistoryStreamProvider);

    return rawData.when(
      data: (history) {
        if (history.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(
                    LucideIcons.bookOpen,
                    size: 48,
                    color: theme.colorScheme.textTertiary,
                  ),
                  Text(
                    '暂无阅读历史',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: history
              .map(
                (h) => ReadingHistoryCard(
                  history: h,
                  onTap: () => appRouter.pushNamed(
                    '阅读页面',
                    pathParameters: {'id': h.comicId},
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            '加载失败',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.textSecondary,
            ),
          ),
        ),
      ),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class CustomTextField extends HookWidget {
  const CustomTextField({super.key, this.onChanged, this.hintText = ""});

  final ValueChanged<String>? onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController controller = useTextEditingController();
    final FocusNode focusNode = useFocusNode();
    final isFocused = useState(false);

    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;

      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused.value
              ? colorScheme.primary
              : colorScheme.borderMedium,
          width: 0.8,
        ),
        boxShadow: isFocused.value
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.4),
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          // 左侧搜索图标
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              LucideIcons.search,
              size: 16,
              color: isFocused.value
                  ? colorScheme.primary
                  : colorScheme.textPlaceholder,
            ),
          ),

          // 输入框主体
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: TextStyle(fontSize: 13, color: colorScheme.textPrimary),
              cursorColor: colorScheme.onSurface,
              cursorWidth: 0.8,
              cursorHeight: 16,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: colorScheme.textPlaceholder,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // 右侧清除按钮 (仅当有内容时显示)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox(width: 12);

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      LucideIcons.circleX,
                      size: 14,
                      color: colorScheme.textPlaceholder,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
