import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_page.dart';

import '../../../widgetbook/lab/navigation/md3e_lab_catalog_navigation.dart';

import 'package:hentai_library/shared/domain/models/enums.dart';

import '../../support/pump_app.dart';

class _AnchorRemovalHost extends StatefulWidget {
  const _AnchorRemovalHost();

  @override
  State<_AnchorRemovalHost> createState() => _AnchorRemovalHostState();
}

class _AnchorRemovalHostState extends State<_AnchorRemovalHost> {
  bool _showAnchor = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showAnchor
          ? Builder(
              builder: (BuildContext anchorContext) {
                return TextButton(
                  onPressed: () {
                    openLabCatalogDetail(
                      anchorContext,
                      displayTarget: LibraryDisplayTarget.comics,
                      catalogIndex: 0,
                    );
                    // 锚点在路由 builder 执行前被移除，模拟目录刷新后的列表项失效。
                    setState(() => _showAnchor = false);
                  },
                  child: const Text('open'),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }
}

void main() {
  testWidgets('打开详情路由时锚点已失效也不应抛出 deactivated 断言', (WidgetTester tester) async {
    await pumpApp(tester, home: const _AnchorRemovalHost());

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ComicDetailLayout), findsOneWidget);
  });
}
