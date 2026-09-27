import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_selection_notifier.dart';

class LibraryReorderModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() {
    ref.read(catalogSelectionProvider.notifier).exit();
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
