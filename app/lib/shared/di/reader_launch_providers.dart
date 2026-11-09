import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/ports/reader_launch_port.dart';

final Provider<ReaderLaunchPort> readerLaunchPortProvider = injectedDi(
  'readerLaunchPortProvider',
);
