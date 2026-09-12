import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_auto_play_carry.g.dart';

/// Carries session autoplay across Series volume switches (pushReplacement).
///
/// [autoPlayEnabled] stays session-only and is not persisted; this keepAlive
/// flag restores it on the next [ReaderController] after [switchComic].
@Riverpod(keepAlive: true)
class ReaderAutoPlayCarry extends _$ReaderAutoPlayCarry {
  @override
  bool build() => false;

  void arm(bool enabled) {
    state = enabled;
  }

  bool take() {
    final bool value = state;
    state = false;
    return value;
  }
}
