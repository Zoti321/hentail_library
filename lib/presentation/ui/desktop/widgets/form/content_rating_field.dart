import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/input/my_toggle_switch.dart';

class ContentRatingField extends StatelessWidget {
  final bool isR18;
  final Function(bool) onChanged;
  final String labelText;

  const ContentRatingField({
    super.key,
    required this.isR18,
    required this.onChanged,
    this.labelText = "内容分级",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 6,
      children: [
        FormLabel(labelText),
        GestureDetector(
          onTap: () => onChanged(!isR18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isR18
                  ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isR18
                    ? Theme.of(context).colorScheme.error.withOpacity(0.3)
                    : Theme.of(context).colorScheme.borderMedium,
              ),
            ),
            child: Row(
              spacing: 12,
              children: [
                MyToggleSwitch(checked: isR18),
                Text(
                  isR18 ? "NSFW" : "",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isR18
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
