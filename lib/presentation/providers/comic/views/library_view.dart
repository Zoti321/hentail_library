import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_view.freezed.dart';
part 'library_view.g.dart';

@freezed
abstract class LibraryViewState with _$LibraryViewState {
  factory LibraryViewState({@Default(true) bool isGridView}) =
      _LibraryViewState;
}

@riverpod
class LibraryViewNotifier extends _$LibraryViewNotifier {
  @override
  LibraryViewState build() {
    return LibraryViewState();
  }
}
