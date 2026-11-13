import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<Future<Uint8List?> Function({Uint8List? bytes, String? path})>
readTagDictionaryFileProvider = requiredProvider(
  'readTagDictionaryFileProvider',
);
