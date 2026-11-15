import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/resource_metadata/presentation/writeback_providers.dart';

class WritebackLifecycle extends ConsumerStatefulWidget {
  const WritebackLifecycle({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<WritebackLifecycle> createState() => _WritebackLifecycleState();
}

class _WritebackLifecycleState extends ConsumerState<WritebackLifecycle>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = true;
  bool _running = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_tick()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      unawaited(_tick());
    }
  }

  Future<void> _tick() async {
    if (!_active || _running || !mounted) {
      return;
    }
    _running = true;
    try {
      final gateway = ref.read(writebackGatewayProvider);
      final revision = ref.read(writebackRevisionProvider.notifier);
      for (var count = 0; count < 10 && mounted && _active; count++) {
        if (!await gateway.processNext()) {
          break;
        }
        if (mounted) {
          revision.changed();
        }
      }
    } catch (_) {
      // Busy/uninitialized core is retried on the next lifecycle tick.
    } finally {
      _running = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
