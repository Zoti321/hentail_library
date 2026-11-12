import 'package:hentai_library/core/async/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test(
    'cancellation completes all listeners once and preserves the first reason',
    () async {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
      final first = token.whenCancelled;
      final second = token.whenCancelled;
      final reason = StateError('cancelled');
      token.cancel(reason);
      token.cancel('later');
      expect(token.isCancelled, isTrue);
      expect(token.reason, same(reason));
      expect(await first, same(reason));
      expect(await second, same(reason));
      expect(await token.whenCancelled, same(reason));
    },
  );
}
