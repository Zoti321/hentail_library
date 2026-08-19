import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Active (focused) chrome for [CustomTextField]: border color only, no glow.
@visibleForTesting
BoxDecoration customTextFieldDecoration({
  required bool isFocused,
  required Color surface,
  required Color focusedBorder,
  required Color idleBorder,
}) {
  return BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isFocused ? focusedBorder : idleBorder,
      width: 0.8,
    ),
  );
}

/// 与历史页工具栏一致的搜索框：聚焦高亮、左侧搜索图标、右侧清除。
class CustomTextField extends HookWidget {
  const CustomTextField({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.hintText = '',
    this.controller,
    this.autofocus = false,
  });

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final bool autofocus;

  /// When set, this controller is used instead of an internal one (e.g. dialog reset).
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextEditingController internalController = useTextEditingController();
    final TextEditingController effectiveController =
        controller ?? internalController;
    final FocusNode focusNode = useFocusNode();
    final isFocused = useState(false);

    useEffect(() {
      void listener() => isFocused.value = focusNode.hasFocus;

      focusNode.addListener(listener);
      if (autofocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
      }
      return () => focusNode.removeListener(listener);
    }, [focusNode, autofocus]);

    return Container(
      height: 40,
      decoration: customTextFieldDecoration(
        isFocused: isFocused.value,
        surface: colorScheme.surface,
        focusedBorder: colorScheme.primary,
        idleBorder: colorScheme.hentai.borderMedium,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              LucideIcons.search,
              size: 16,
              color: isFocused.value
                  ? colorScheme.primary
                  : colorScheme.hentai.textPlaceholder,
            ),
          ),
          Expanded(
            child: TextField(
              controller: effectiveController,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.hentai.textPrimary,
              ),
              cursorColor: colorScheme.onSurface,
              cursorWidth: 0.8,
              cursorHeight: 16,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: colorScheme.hentai.textPlaceholder,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: effectiveController,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox(width: 12);

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    effectiveController.clear();
                    onChanged?.call('');
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      LucideIcons.circleX,
                      size: 14,
                      color: colorScheme.hentai.textPlaceholder,
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
