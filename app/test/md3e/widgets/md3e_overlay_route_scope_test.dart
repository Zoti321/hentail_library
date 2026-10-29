import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_page.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_lab_catalog_navigation.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

import '../../support/pump_md3e_app.dart';

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
                    openMd3eLabCatalogDetail(
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
    await pumpMd3eApp(tester, home: const _AnchorRemovalHost());

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Md3eComicDetailPage), findsOneWidget);
  });
}
