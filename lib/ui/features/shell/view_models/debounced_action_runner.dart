import 'dart:async';

class DebouncedActionRunner {
  DebouncedActionRunner({required this.duration});
  final Duration duration;
  Timer? _timer;
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }
  void dispose() {
    _timer?.cancel();
  }
}
