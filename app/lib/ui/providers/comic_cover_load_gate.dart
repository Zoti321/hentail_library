import 'dart:async';
import 'dart:collection';

/// Limits concurrent comic-cover FRB loads from the Flutter side.
class ComicCoverLoadGate {
  ComicCoverLoadGate._();

  static const int maxConcurrent = 8;

  static int _active = 0;
  static final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  static Future<T> run<T>(Future<T> Function() action) async {
    await _acquire();
    try {
      return await action();
    } finally {
      _release();
    }
  }

  static Future<void> _acquire() async {
    if (_active < maxConcurrent) {
      _active++;
      return;
    }
    final Completer<void> completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
    _active++;
  }

  static void _release() {
    _active--;
    if (_waitQueue.isEmpty) {
      return;
    }
    _waitQueue.removeFirst().complete();
  }
}
