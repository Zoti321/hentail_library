import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/presentation/views/home/home_layout.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_aggregate_stats_section.dart';
import 'package:hentai_library/features/home/presentation/views/home/patterns/home_page_copy.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/home_library_management_section.dart';
import 'package:hentai_library/features/reading_stats/public.dart';

import '../../../../../../widgetbook/preview/md3e_home_page_preview_data.dart';
import '../../../../../support/pump_app.dart';

void main() {
  testWidgets(
    'personal center adapts to available width and keeps navigation',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final double width in <double>[280, 600, 1000]) {
        bool tagsOpened = false;
        await pumpApp(
          tester,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: HomeAggregateStatsSection(
                    counts: HomePagePreviewData.sampleAggregateCounts(),
                    activityStats: const ReadingActivityStats(
                      finishedCount: 12,
                      totalDuration: Duration(hours: 3),
                    ),
                    onOpenHistory: () {},
                    onOpenTrash: () {},
                    onOpenTags: () => tagsOpened = true,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('个人中心'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'width: $width');
        final Offset author = tester.getTopLeft(find.text('作者'));
        final Offset parody = tester.getTopLeft(find.text('原作'));
        final Offset character = tester.getTopLeft(find.text('角色'));
        if (width < 360) {
          expect(parody.dy, greaterThan(author.dy));
        } else {
          expect(parody.dy, author.dy);
          expect(
            character.dy,
            width < 760 ? greaterThan(author.dy) : author.dy,
          );
        }
        await tester.ensureVisible(find.text('标签'));
        await tester.tap(find.text('标签'));
        expect(tagsOpened, isTrue);
        expect(tester.takeException(), isNull);
      }
    },
  );

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
          onOpenMedia: () {},
          libraryManagementSection: HomeLibraryManagementSection(
            libraries: HomePagePreviewData.sampleLibraries(),
            onAddLocalLibrary: () {},
            onAddRemoteLibrary: () {},
          ),
        ),
      ),
    );

    expect(find.text(HomePageCopy.aggregateStatsSectionTitle), findsOneWidget);
    expect(find.text(HomePageCopy.activityStatsTitle), findsOneWidget);
    expect(find.text('读完'), findsOneWidget);
    expect(find.text('阅读时长'), findsOneWidget);
    expect(find.text('阅读历史'), findsOneWidget);
    expect(find.text('查看阅读记录'), findsOneWidget);
    expect(find.text('垃圾桶'), findsOneWidget);
    expect(find.text('可恢复删除'), findsOneWidget);
    expect(find.text('媒体'), findsOneWidget);
    expect(find.text('查看本地漫画资源的元数据写入概况。'), findsOneWidget);
    expect(find.text('进入'), findsNothing);
    expect(find.textContaining('2552'), findsOneWidget);
    expect(find.text('我的漫画库'), findsOneWidget);
    expect(find.text('本机漫画'), findsOneWidget);
    expect(find.text('NAS WebDAV'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
