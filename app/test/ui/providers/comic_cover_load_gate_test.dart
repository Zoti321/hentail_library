import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/providers/comic_cover_load_gate.dart';

void main() {
  test('ComicCoverLoadGate limits concurrent executions', () async {
    int inFlight = 0;
    int maxObserved = 0;

    Future<void> task() {
      return ComicCoverLoadGate.run(() async {
        inFlight++;
        maxObserved = inFlight > maxObserved ? inFlight : maxObserved;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        inFlight--;
      });
    }

    await Future.wait(List<Future<void>>.generate(16, (_) => task()));

    expect(maxObserved, lessThanOrEqualTo(ComicCoverLoadGate.maxConcurrent));
    expect(inFlight, 0);
  });
}
