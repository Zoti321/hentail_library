import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';

class MyToggleSwitch extends StatefulWidget {
  const MyToggleSwitch({super.key, required this.checked, this.onChange});

  final bool checked;
  final VoidCallback? onChange;

  @override
  State<MyToggleSwitch> createState() => _MyToggleSwitchState();
}

class _MyToggleSwitchState extends State<MyToggleSwitch> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onChange,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 20,
          decoration: BoxDecoration(
            color: widget.checked
                ? theme.colorScheme.primary
                : theme.colorScheme.borderSubtle,
            border: Border.all(
              color: widget.checked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.borderMedium,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: widget.checked
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
