import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';

/// Feedback loop for: series grid tap → unknown route name: ????
void main() {
  test('registered comic-detail name resolves; corrupted ???? does not', () {
    expect(
      appRouter.namedLocation(
        '漫画详情',
        pathParameters: <String, String>{'id': 'comic-1'},
      ),
      '/comic/comic-1',
    );

    expect(
      () => appRouter.namedLocation(
        '????',
        pathParameters: <String, String>{'id': 'comic-1'},
      ),
      throwsA(
        isA<AssertionError>().having(
          (AssertionError e) => e.message,
          'message',
          contains('unknown route name'),
        ),
      ),
    );
  });

  test('series detail comics grid pushNamed uses registered route name', () {
    final File source = File(
      'lib/ui/features/library/views/series_detail_page/widgets/series_detail_comics_grid.dart',
    );
    final String text = source.readAsStringSync();
    expect(
      text.contains("'????'"),
      isFalse,
      reason: 'route name was corrupted (encoding) — must not pushNamed ????',
    );
    expect(
      text.contains("pushNamed(\n                '漫画详情'") ||
          text.contains("pushNamed(\n              '漫画详情'") ||
          RegExp(r"pushNamed\(\s*'漫画详情'").hasMatch(text),
      isTrue,
      reason: 'must navigate with registered GoRoute name 漫画详情',
    );
  });
}
