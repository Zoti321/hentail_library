import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:hentai_library/shared/ui/contracts/library_browse_fallback_command.dart';

final Provider<GoLibraryBrowseFallbackCommand>
goLibraryBrowseFallbackCommandProvider = requiredProvider(
  'goLibraryBrowseFallbackCommandProvider',
);
