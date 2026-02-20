import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';

class ReadModeToggleButton extends StatelessWidget {
  const ReadModeToggleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isVertical,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isVertical;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Semantics(
        selected: isActive,
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? cs.activeButtonBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              spacing: 6,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? cs.readerTextOnWhite
                      : cs.readerTextIconPrimary,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? cs.readerTextOnWhite
                        : cs.readerTextIconPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
