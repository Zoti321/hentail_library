import 'package:window_manager/window_manager.dart';

import 'window_manager_bindings.dart';

/// Prevent-close requires an explicit response to OS close / Alt+F4.
class WindowCloseListener with WindowListener {
  void attach() => windowManager.addListener(this);
  void detach() => windowManager.removeListener(this);

  @override
  void onWindowClose() => windowManagerClose();
}
