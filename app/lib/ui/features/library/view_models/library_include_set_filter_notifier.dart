import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_include_set_filter_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibraryLanguageFilter extends _$LibraryLanguageFilter {
  static const String _storageKey = 'library_language_filter';

  @override
  Future<Set<String>> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_storageKey);
    return stored?.toSet() ?? const <String>{};
  }

  Future<void> toggle(String name) async {
    final Set<String> current = await future;
    final Set<String> updated = Set<String>.of(current);
    if (updated.contains(name)) {
      updated.remove(name);
    } else {
      updated.add(name);
    }
    state = AsyncValue<Set<String>>.data(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, updated.toList());
  }

  Future<void> clear() async {
    state = const AsyncValue<Set<String>>.data(<String>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

@Riverpod(keepAlive: true)
class LibraryParodyFilter extends _$LibraryParodyFilter {
  static const String _storageKey = 'library_parody_filter';

  @override
  Future<Set<String>> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_storageKey);
    return stored?.toSet() ?? const <String>{};
  }

  Future<void> toggle(String name) async {
    final Set<String> current = await future;
    final Set<String> updated = Set<String>.of(current);
    if (updated.contains(name)) {
      updated.remove(name);
    } else {
      updated.add(name);
    }
    state = AsyncValue<Set<String>>.data(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, updated.toList());
  }

  Future<void> clear() async {
    state = const AsyncValue<Set<String>>.data(<String>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

@Riverpod(keepAlive: true)
class LibraryCharacterFilter extends _$LibraryCharacterFilter {
  static const String _storageKey = 'library_character_filter';

  @override
  Future<Set<String>> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_storageKey);
    return stored?.toSet() ?? const <String>{};
  }

  Future<void> toggle(String name) async {
    final Set<String> current = await future;
    final Set<String> updated = Set<String>.of(current);
    if (updated.contains(name)) {
      updated.remove(name);
    } else {
      updated.add(name);
    }
    state = AsyncValue<Set<String>>.data(updated);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, updated.toList());
  }

  Future<void> clear() async {
    state = const AsyncValue<Set<String>>.data(<String>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
