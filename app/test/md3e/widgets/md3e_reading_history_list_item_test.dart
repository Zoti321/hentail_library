import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eReadingHistoryListItem shows title, progress, and actions', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 400,
          child: Md3eReadingHistoryListItem(
            title: '测试漫画',
            cover: const ColoredBox(color: Color(0xFFE0E0E0)),
            currentPage: 12,
            totalPages: 200,
            lastReadTime: DateTime(2026, 1, 1, 12),
            onContinueReading: () {},
            moreMenuEntries: const <Md3eReadingHistoryMoreMenuEntry>[
              Md3eReadingHistoryMoreMenuEntry(label: '删除'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('测试漫画'), findsOneWidget);
    expect(find.text('12/200'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
