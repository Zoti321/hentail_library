import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/reader_launch_port.dart';

final Provider<ReaderLaunchPort> readerLaunchPortProvider =
    Provider<ReaderLaunchPort>(
      (Ref ref) => throw UnimplementedError(
        'readerLaunchPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
