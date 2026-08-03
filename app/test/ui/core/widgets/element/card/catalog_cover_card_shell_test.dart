import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/catalog_cover_card_shell.dart';

void main() {
  testWidgets('long press reports the gesture globalPosition', (
    WidgetTester tester,
  ) async {
    LongPressStartDetails? captured;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 360,
            child: CatalogCoverCardShell(
              onLongPressStart: (LongPressStartDetails details) {
                captured = details;
              },
              cover: const ColoredBox(color: Colors.grey),
              info: (_) => const Text('title'),
            ),
          ),
        ),
      ),
    );

    final Offset pressAt = tester.getCenter(find.byType(CatalogCoverCardShell));
    await tester.longPressAt(pressAt);

    expect(captured, isNotNull);
    expect(captured!.globalPosition, pressAt);
  });
}
