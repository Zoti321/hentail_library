import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_reader_page_lab_host.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_copy.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_preview_data.dart';

import '../../support/pump_md3e_app.dart';

const String _advancePrompt = '再次翻页将进入下一卷';
const String _retreatPrompt = '再次翻页将进入上一卷';

Future<void> _pumpHost(
  WidgetTester tester,
  Md3eReaderPagePreviewData preview,
) async {
  await tester.binding.setSurfaceSize(const Size(1024, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpMd3eApp(
    tester,
    home: SizedBox(
      width: 1024,
      height: 800,
      child: Md3eReaderPageLabHost(preview: preview),
    ),
  );
  // 先隐藏 chrome，之后的左右点击才会翻页。
  await tester.tapAt(const Offset(512, 400));
  await tester.pumpAndSettle();
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tapAt(const Offset(900, 400));
  await tester.pumpAndSettle();
}

Future<void> _tapPrev(WidgetTester tester) async {
  await tester.tapAt(const Offset(100, 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'at last page, first next shows advance prompt without leaving volume',
    (WidgetTester tester) async {
      await _pumpHost(
        tester,
        const Md3eReaderPagePreviewData(
          title: '第 01 卷',
          totalPages: 3,
          initialPage: 3,
        ),
      );

      await _tapNext(tester);

      expect(find.text(_advancePrompt), findsOneWidget);
      expect(
        find.text(Md3eReaderPageCopy.viewportPlaceholder(3)),
        findsOneWidget,
      );
      expect(find.text('第 01 卷'), findsOneWidget);
    },
  );

  testWidgets('second next at last page enters next volume from page 1', (
    WidgetTester tester,
  ) async {
    await _pumpHost(
      tester,
      const Md3eReaderPagePreviewData(
        title: '第 01 卷',
        totalPages: 3,
        initialPage: 3,
      ),
    );

    await _tapNext(tester);
    await _tapNext(tester);

    expect(find.text('第 02 卷'), findsOneWidget);
    expect(
      find.text(Md3eReaderPageCopy.viewportPlaceholder(1)),
      findsOneWidget,
    );
    expect(find.text(_advancePrompt), findsNothing);
  });

  testWidgets('at first page, first prev shows retreat prompt', (
    WidgetTester tester,
  ) async {
    await _pumpHost(
      tester,
      const Md3eReaderPagePreviewData(
        title: '第 02 卷',
        totalPages: 3,
        currentVolumeId: 'vol-02',
      ),
    );

    await _tapPrev(tester);

    expect(find.text(_retreatPrompt), findsOneWidget);
    expect(find.text('第 02 卷'), findsOneWidget);
  });

  testWidgets('second prev at first page enters previous volume from page 1', (
    WidgetTester tester,
  ) async {
    await _pumpHost(
      tester,
      const Md3eReaderPagePreviewData(
        title: '第 02 卷',
        totalPages: 3,
        currentVolumeId: 'vol-02',
      ),
    );

    await _tapPrev(tester);
    await _tapPrev(tester);

    expect(find.text('第 01 卷'), findsOneWidget);
    expect(
      find.text(Md3eReaderPageCopy.viewportPlaceholder(1)),
      findsOneWidget,
    );
  });

  testWidgets('last volume at last page shows no prompt and does not move', (
    WidgetTester tester,
  ) async {
    await _pumpHost(
      tester,
      const Md3eReaderPagePreviewData(
        title: '第 03 卷',
        totalPages: 3,
        initialPage: 3,
        currentVolumeId: 'vol-03',
      ),
    );

    await _tapNext(tester);
    await _tapNext(tester);

    expect(find.text(_advancePrompt), findsNothing);
    expect(find.text('第 03 卷'), findsOneWidget);
    expect(
      find.text(Md3eReaderPageCopy.viewportPlaceholder(3)),
      findsOneWidget,
    );
  });

  testWidgets('moving away from boundary clears pending prompt', (
    WidgetTester tester,
  ) async {
    await _pumpHost(
      tester,
      const Md3eReaderPagePreviewData(
        title: '第 01 卷',
        totalPages: 3,
        initialPage: 3,
      ),
    );

    await _tapNext(tester);
    expect(find.text(_advancePrompt), findsOneWidget);

    await _tapPrev(tester);
    expect(find.text(_advancePrompt), findsNothing);
    expect(
      find.text(Md3eReaderPageCopy.viewportPlaceholder(2)),
      findsOneWidget,
    );

    // 回到边界后第一次翻页应重新提示，而不是直接跨卷。
    await _tapNext(tester);
    expect(
      find.text(Md3eReaderPageCopy.viewportPlaceholder(3)),
      findsOneWidget,
    );
    await _tapNext(tester);
    expect(find.text('第 01 卷'), findsOneWidget);
    expect(find.text(_advancePrompt), findsOneWidget);
  });
}
