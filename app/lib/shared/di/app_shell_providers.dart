import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<VoidCallback> appShellOpenNavigationDrawerProvider =
    Provider<VoidCallback>(
      (Ref ref) => throw UnimplementedError(
        'appShellOpenNavigationDrawerProvider 未注入，请在 bootstrap 中 override',
      ),
    );
