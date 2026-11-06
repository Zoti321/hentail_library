import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/outlined_text_field.dart';

/// 管理页新建实体：单行 outlined 输入（Dialog 与桌面内联共用）。
class ManagementEntityNameField extends StatelessWidget {
  const ManagementEntityNameField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return OutlinedTextField(
      label: label,
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.done,
      onSubmitted: (String value) {
        final String trimmed = value.trim();
        if (trimmed.isEmpty) {
          return;
        }
        onSubmitted?.call(trimmed);
      },
    );
  }
}
