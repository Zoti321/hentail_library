import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/hosts/md3e_reader_page_lab_host.dart';

import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_page_copy.dart';

import '../../../widgetbook/preview/md3e_reader_page_preview_data.dart';

import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_viewport_status.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('shows series title, viewport placeholder, and progress slider', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await pumpApp(
      tester,
      home: const SizedBox(
        width: 1024,
        height: 800,
        child: ReaderPageLabHost(),
      ),
    );
    expect(find.text('葬送的芙莉莲'), findsOneWidget);
    expect(find.text('第 01 卷'), findsOneWidget);
    expect(find.text(ReaderPageCopy.viewportPlaceholder(3)), findsOneWidget);
    expect(find.byType(M3ESlider), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tap zones paginate when chrome hidden', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await pumpApp(
      tester,
      home: const SizedBox(
        width: 1024,
        height: 800,
        child: ReaderPageLabHost(),
      ),
    );
    await tester.tapAt(const Offset(512, 400));
    await tester.pumpAndSettle();
    expect(find.text(ReaderPageCopy.viewportPlaceholder(3)), findsOneWidget);

    await tester.tapAt(const Offset(900, 400));
    await tester.pumpAndSettle();
    expect(find.text(ReaderPageCopy.viewportPlaceholder(4)), findsOneWidget);

    await tester.tapAt(const Offset(100, 400));
    await tester.pumpAndSettle();
    expect(find.text(ReaderPageCopy.viewportPlaceholder(3)), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('loading shows progress and no page placeholder', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await pumpApp(
      tester,
      home: const SizedBox(
        width: 1024,
        height: 800,
        child: ReaderPageLabHost(
          preview: ReaderPagePreviewData(
            title: '第 01 卷',
            totalPages: 24,
            initialPage: 3,
            viewportStatus: ReaderViewportStatus.loading,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(ReaderPageCopy.viewportLoading), findsOneWidget);
    expect(find.text(ReaderPageCopy.viewportPlaceholder(3)), findsNothing);

    // 加载指示器持续动画，不能用 pumpAndSettle。
    await tester.tapAt(const Offset(900, 400));
    await tester.pump();
    expect(find.text(ReaderPageCopy.viewportPlaceholder(3)), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('open error blocks paging until retry restores viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await pumpApp(
      tester,
      home: const SizedBox(
        width: 1024,
        height: 800,
        child: ReaderPageLabHost(
          preview: ReaderPagePreviewData(
            title: '第 01 卷',
            totalPages: 24,
            initialPage: 3,
            viewportStatus: ReaderViewportStatus.error,
          ),
        ),
      ),
    );
    expect(find.text(ReaderPageCopy.viewportErrorMessage), findsOneWidget);
    expect(find.text(ReaderPageCopy.viewportErrorRetry), findsOneWidget);

    await tester.tapAt(const Offset(900, 400));
    await tester.pumpAndSettle();
    expect(find.text(ReaderPageCopy.viewportErrorMessage), findsOneWidget);

    await tester.tap(find.text(ReaderPageCopy.viewportErrorRetry));
    await tester.pumpAndSettle();
    expect(find.text(ReaderPageCopy.viewportErrorMessage), findsNothing);
    expect(find.text(ReaderPageCopy.viewportPlaceholder(3)), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
