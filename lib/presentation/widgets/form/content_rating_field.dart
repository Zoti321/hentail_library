import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/presentation/widgets/form/fluent_text_field.dart';

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
                AnimatedContainer(
                  duration: 100.ms,
                  curve: Curves.easeInOut,
                  width: 32,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isR18
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.borderStrong,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      AnimatedPositioned(
                        duration: 200.ms,
                        left: isR18 ? 18 : 2,
                        top: 2,
                        bottom: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
