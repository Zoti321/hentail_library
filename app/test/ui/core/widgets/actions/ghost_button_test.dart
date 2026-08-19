import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('compact icon button expands hit area to 44', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: GhostButton.icon(
            icon: LucideIcons.menu,
            tooltip: 'Open menu',
            onPressed: _noop,
          ),
        ),
      ),
    );

    final IconButton button = tester.widget(find.byType(IconButton));
    expect(
      button.style?.minimumSize?.resolve(<WidgetState>{}),
      const Size(44, 44),
    );
    expect(button.style?.tapTargetSize, MaterialTapTargetSize.padded);
  });
}

void _noop() {}
