import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/settings_grouped_list_pattern.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('settings grouped list renders section header and row', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Md3eSettingsGroupedListPattern(
        sections: <({String header, List<Md3eSettingsRow> rows})>[
          (
            header: '外观',
            rows: <Md3eSettingsRow>[
              const Md3eSettingsRow(title: '主题'),
            ],
          ),
        ],
      ),
    );
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
  });
}
