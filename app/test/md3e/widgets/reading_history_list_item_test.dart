import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/reading_history_list_item.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('ReadingHistoryListItem shows title, progress, and actions', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 400,
          child: ReadingHistoryListItem(
            title: '测试漫画',
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
            currentPage: 12,
            totalPages: 200,
            lastReadTime: DateTime(2026, 1, 1, 12),
            onContinueReading: () {},
            moreMenuEntries: const <ReadingHistoryMoreMenuEntry>[
              ReadingHistoryMoreMenuEntry(label: '删除'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('测试漫画'), findsOneWidget);
    expect(find.text('12/200'), findsOneWidget);
    expect(find.text('2026年01月01日'), findsOneWidget);
    expect(find.byType(M3EProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
