import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/frb_zone_guard.dart';
import 'package:hentai_library/src/rust/api/init.dart';

void main() {
  late List<FlutterErrorDetails> presented;

  setUp(() {
    presented = <FlutterErrorDetails>[];
    final FlutterExceptionHandler previous = FlutterError.presentError;
    FlutterError.presentError = presented.add;
    addTearDown(() => FlutterError.presentError = previous);
  });

  test('presents mapped AppException for FRB errors', () {
    handleUncaughtFrbZoneError(
      const HentaiErrorDto(
        code: 'DbQueryFailed',
        message: 'no such table',
        context: 'comics',
      ),
      StackTrace.empty,
    );

    expect(presented, hasLength(1));
    expect(
      presented.single.exception,
      isA<SyncException>().having(
        (SyncException e) => e.message,
        'message',
        'no such table (comics)',
      ),
    );
  });

  test('ignores non-FRB errors', () {
    handleUncaughtFrbZoneError(StateError('unrelated'), StackTrace.empty);

    expect(presented, isEmpty);
  });

  test('ignores benign stream closed errors', () {
    handleUncaughtFrbZoneError(
      const HentaiErrorDto(
        code: 'Validation',
        message: 'stream closed',
        context: null,
      ),
      StackTrace.empty,
    );

    expect(presented, isEmpty);
  });
}
