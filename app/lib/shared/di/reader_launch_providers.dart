import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/read_session_launch_port.dart';

final Provider<ReadSessionLaunchPort> readSessionLaunchPortProvider =
    Provider<ReadSessionLaunchPort>(
      (Ref ref) => throw UnimplementedError(
        'readSessionLaunchPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );
