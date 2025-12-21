import 'dart:async';

import 'package:flutter/material.dart';

/// 终端风格旋转字符（`-` `\` `|` `/`），用于不确定进度。
class TerminalSpinner extends StatefulWidget {
  const TerminalSpinner({super.key, this.size = 14, this.color});

  final double size;
  final Color? color;

  @override
  State<TerminalSpinner> createState() => _TerminalSpinnerState();
}

class _TerminalSpinnerState extends State<TerminalSpinner> {
  static const _chars = ['-', r'\', '|', '/'];

  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() => _i = (_i + 1) % _chars.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: Text(
          _chars[_i],
          style: TextStyle(
            fontSize: widget.size,
            height: 1,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
