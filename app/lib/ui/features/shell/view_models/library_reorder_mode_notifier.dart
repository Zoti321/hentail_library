import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryReorderModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;

  void exit() {
    if (state) {
      state = false;
    }
  }
}

final libraryReorderModeProvider =
    NotifierProvider<LibraryReorderModeNotifier, bool>(
      LibraryReorderModeNotifier.new,
    );
