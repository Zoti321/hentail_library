import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';

/// 管理页新建实体：单行 outlined 输入（Dialog 与桌面内联共用）。
class Md3eManagementEntityNameField extends StatelessWidget {
  const Md3eManagementEntityNameField({
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
    return Md3eOutlinedTextField(
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
