import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/page_size_menu.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_mode.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_header.dart';

import '../../../../../support/localized_test_app.dart';

Series _series() =>
    Series(id: 'series-1', name: 'Demo Series', folderPath: '/lib/Demo');

Future<ProviderContainer> _pumpHeader(WidgetTester tester) async {
  final ProviderContainer container = ProviderContainer();
  // 进入 Series reorder mode 并保活，避免 autoDispose 在 pump 前复位。
  container.listen(seriesReorderModeProvider('series-1'), (_, _) {});
  container.read(seriesReorderModeProvider('series-1').notifier).enter();

  final config = localizedTestAppConfig();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: config.locale,
        localizationsDelegates: config.delegates,
        supportedLocales: config.locales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: SeriesDetailHeader(series: _series())),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets(
    'reorder-mode header shows exit + drag title, hides browse chrome',
    (WidgetTester tester) async {
      await _pumpHeader(tester);

      // Exit control + drag-mode indicator present.
      expect(find.byTooltip('退出排序'), findsOneWidget);
      expect(find.text('拖拽排序'), findsOneWidget);

      // Normal browsing chrome hidden.
      expect(find.byTooltip('返回'), findsNothing);
      expect(find.byTooltip('编辑系列'), findsNothing);
      expect(find.byType(PageSizeMenuButton), findsNothing);
    },
  );
}
