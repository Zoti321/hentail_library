import 'dart:async';

class CancellationToken {
  final Completer<Object?> _cancelled = Completer<Object?>();

  bool get isCancelled => _cancelled.isCompleted;
  Object? _reason;
  Object? get reason => _reason;
  Future<Object?> get whenCancelled => _cancelled.future;

  void cancel([Object? reason]) {
    if (isCancelled) {
      return;
    }
    _reason = reason;
    _cancelled.complete(reason);
  }
}

class OperationCancelledException implements Exception {
  const OperationCancelledException();
}
