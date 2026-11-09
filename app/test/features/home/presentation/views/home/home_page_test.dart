import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_page.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_page_copy.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_management_section.dart';
import 'package:hentai_library/shared/domain/library/reading_activity_stats.dart';

import '../../../../../../widgetbook/preview/md3e_home_page_preview_data.dart';
import '../../../../../support/pump_app.dart';

void main() {
  testWidgets('shows library management section with preview rows', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    await pumpApp(
      tester,
      home: SizedBox(
        width: 900,
        height: 900,
        child: HomeLayout(
          aggregateCounts: HomePagePreviewData.sampleAggregateCounts(),
          activityStats: const ReadingActivityStats(
            finishedCount: 12,
            totalDuration: Duration(hours: 3, minutes: 20),
          ),
          onOpenHistory: () {},
          onOpenTrash: () {},
          libraryManagementSection: HomeLibraryManagementSection(
            libraries: HomePagePreviewData.sampleLibraries(),
            onAddLocalLibrary: () {},
            onAddRemoteLibrary: () {},
          ),
        ),
      ),
    );

    expect(find.text(HomePageCopy.aggregateStatsSectionTitle), findsOneWidget);
    expect(find.text('读完'), findsOneWidget);
    expect(find.text('阅读时长'), findsWidgets);
    expect(find.text('阅读历史'), findsOneWidget);
    expect(find.text('查看阅读记录'), findsOneWidget);
    expect(find.text('垃圾桶'), findsOneWidget);
    expect(find.text('可恢复删除'), findsOneWidget);
    expect(find.text('进入'), findsNothing);
    expect(find.textContaining('2552'), findsOneWidget);
    expect(find.text('我的漫画库'), findsOneWidget);
    expect(find.text('本机漫画'), findsOneWidget);
    expect(find.text('NAS WebDAV'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
