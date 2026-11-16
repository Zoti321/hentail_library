import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/infrastructure/open_author_link.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  const url = 'https://www.pixiv.net/users/123?query=a%20b';
  late List<MethodCall> calls;
  late bool canLaunch;
  late bool launched;
  String? failingMethod;

  setUp(() {
    calls = [];
    canLaunch = true;
    launched = true;
    failingMethod = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == failingMethod) {
        throw PlatformException(
          code: 'native_failure',
          message: 'launcher failed',
        );
      }
      return switch (call.method) {
        'canLaunch' => canLaunch,
        'launch' => launched,
        _ => throw StateError('Unexpected method: ${call.method}'),
      };
    });
  });
  tearDown(
    () =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );

  test('checks availability then opens the unchanged URL externally', () async {
    await openAuthorLink(url);
    expect(calls.map((call) => call.method), ['canLaunch', 'launch']);
    expect(calls.first.arguments, {'url': url});
    expect(calls.last.arguments, containsPair('url', url));
    expect(calls.last.arguments, containsPair('useSafariVC', false));
    expect(calls.last.arguments, containsPair('useWebView', false));
    expect(calls.last.arguments, containsPair('universalLinksOnly', false));
  });

  test('an unavailable handler fails without attempting launch', () async {
    canLaunch = false;
    await expectLater(openAuthorLink(url), throwsStateError);
    expect(calls.map((call) => call.method), ['canLaunch']);
  });

  test('a false launch result is a failure', () async {
    launched = false;
    await expectLater(openAuthorLink(url), throwsStateError);
    expect(calls.map((call) => call.method), ['canLaunch', 'launch']);
  });

  for (final method in ['canLaunch', 'launch']) {
    test('native $method errors propagate without retry', () async {
      failingMethod = method;
      await expectLater(
        openAuthorLink(url),
        throwsA(
          isA<PlatformException>()
              .having((error) => error.code, 'code', 'native_failure')
              .having((error) => error.message, 'message', 'launcher failed'),
        ),
      );
      expect(
        calls.map((call) => call.method),
        method == 'canLaunch' ? ['canLaunch'] : ['canLaunch', 'launch'],
      );
    });
  }

  test('malformed URLs fail before platform calls', () async {
    await expectLater(openAuthorLink('https://['), throwsFormatException);
    expect(calls, isEmpty);
  });
}
