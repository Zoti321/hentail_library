import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoryTagChip extends StatefulWidget {
  final String label;
  final VoidCallback onRemove;

  const CategoryTagChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  State<CategoryTagChip> createState() => _CategoryTagChipState();
}

class _CategoryTagChipState extends State<CategoryTagChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Flexible(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onRemove,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Theme.of(context).colorScheme.warning
                      : Theme.of(context).colorScheme.borderSubtle,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 10,
                  color: _isHovered
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
