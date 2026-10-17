import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';

class LibraryReorderModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() {
    ref.read(catalogSelectionCommandPortProvider).exit();
    state = true;
  }

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
