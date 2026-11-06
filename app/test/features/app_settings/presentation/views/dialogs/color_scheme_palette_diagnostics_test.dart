import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Mirrors production _PaletteCard (Kazumi: [Container] not [ColoredBox]).
class _DiagPaletteCard extends StatelessWidget {
  const _DiagPaletteCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final Hct hct = Hct.fromInt(color.toARGB32());
    final Color primary = Color(Hct.from(hct.hue, 20.0, 90.0).toInt());
    final Color tertiary = Color(Hct.from(hct.hue + 50, 20.0, 85.0).toInt());
    final Color primaryContainer = Color(Hct.from(hct.hue, 30.0, 50.0).toInt());
    final Color surfaceContainerLow =
        M3ETheme.of(context).colorScheme.surfaceContainerLow;

    return SizedBox(
      width: 70,
      height: 70,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipOval(
            child: Column(
              children: <Widget>[
                Expanded(child: Container(color: primary)),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Container(color: tertiary)),
                      Expanded(child: Container(color: primaryContainer)),
                    ],
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

void main() {
  testWidgets('palette card Containers fill Expanded (not zero-size)', (
    WidgetTester tester,
  ) async {
    final M3EThemeData m3e = buildAppM3eThemeData(
      Brightness.light,
      seed: Colors.teal,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: M3ETheme(
          data: m3e,
          child: const Scaffold(
            body: Center(child: _DiagPaletteCard(color: Colors.teal)),
          ),
        ),
      ),
    );

    final List<Size> sizes = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(ClipOval),
            matching: find.byType(Container),
          ),
        )
        .map((Container c) {
          final Element el = tester.element(find.byWidget(c));
          return (el.renderObject! as RenderBox).size;
        })
        .toList();

    expect(sizes, hasLength(3));
    expect(sizes[0], const Size(50, 25));
    expect(sizes[1], const Size(25, 25));
    expect(sizes[2], const Size(25, 25));
  });
}
