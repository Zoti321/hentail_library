import 'dart:async';

/// While [shouldThrottle] is true, coalesce emissions to at most one per
/// [interval] (latest value wins). When not throttling, values pass through.
Stream<T> throttleWhile<T>(
  Stream<T> source, {
  required bool Function() shouldThrottle,
  Duration interval = const Duration(seconds: 2),
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? timer;
  T? pending;
  DateTime? lastEmitAt;

  void emit(T value) {
    lastEmitAt = DateTime.now();
    pending = null;
    if (!controller.isClosed) {
      controller.add(value);
    }
  }

  void flushPending() {
    timer = null;
    final T? value = pending;
    if (value != null) {
      emit(value);
    }
  }

  void onData(T value) {
    if (!shouldThrottle()) {
      timer?.cancel();
      timer = null;
      pending = null;
      emit(value);
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? last = lastEmitAt;
    if (last == null || now.difference(last) >= interval) {
      timer?.cancel();
      timer = null;
      emit(value);
      return;
    }

    pending = value;
    timer ??= Timer(interval - now.difference(last), flushPending);
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        onData,
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          final T? value = pending;
          if (value != null) {
            emit(value);
          }
          controller.close();
        },
      );
    },
    onCancel: () async {
      timer?.cancel();
      await subscription?.cancel();
    },
  );

  return controller.stream;
}
