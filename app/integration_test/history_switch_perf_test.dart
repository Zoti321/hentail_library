
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/app_router.dart';
import 'package:hentai_library/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';

/// 性能采样：在 profile 模式下切换页面，用帧耗时回调统计每次切换的构建/光栅耗时。
///
/// 运行：flutter test integration_test/history_switch_perf_test.dart -d windows --profile
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('history page switch frame timings', (WidgetTester tester) async {
    app.main();
    // 等待启动（窗口、Rust、数据库）与首页稳定。
    await Future<void>.delayed(const Duration(seconds: 10));

    void dumpTree(Element element, int depth) {
      if (depth > 4) {
        return;
      }
      // ignore: avoid_print
      print('[DIAG] ${'  ' * depth}${element.widget.runtimeType}');
      element.visitChildElements((Element child) => dumpTree(child, depth + 1));
    }

    final Element? root = WidgetsBinding.instance.rootElement;
    if (root != null) {
      dumpTree(root, 0);
    }

    // ignore: avoid_print
    print(
      '[DIAG] route=${appRouter.routerDelegate.currentConfiguration.uri} '
      'lifecycle=${SchedulerBinding.instance.lifecycleState} '
      'framesEnabled=${SchedulerBinding.instance.framesEnabled} '
      'visible=${await windowManager.isVisible()} '
      'minimized=${await windowManager.isMinimized()} '
      'focused=${await windowManager.isFocused()}',
    );

    Future<void> measure(String route, String label) async {
      final List<FrameTiming> frames = <FrameTiming>[];
      void onTimings(List<FrameTiming> timings) => frames.addAll(timings);

      SchedulerBinding.instance.addTimingsCallback(onTimings);
      appRouter.go(route);
      await Future<void>.delayed(const Duration(seconds: 4));
      SchedulerBinding.instance.removeTimingsCallback(onTimings);

      _printSummary(label, frames);
      appRouter.go('/home');
      await Future<void>.delayed(const Duration(seconds: 3));
    }

    // 首次进入历史页（冷）→ 再次进入（热），并与管理页对比。
    await measure('/history', 'history_first_visit');
    await measure('/history', 'history_second_visit');
    await measure('/metadata', 'metadata_visit');
  });
}

void _printSummary(String label, List<FrameTiming> frames) {
  if (frames.isEmpty) {
    // ignore: avoid_print
    print('[PERF] $label: 0 frames');
    return;
  }
  final List<double> build = frames
      .map((FrameTiming f) => f.buildDuration.inMicroseconds / 1000)
      .toList();
  final List<double> raster = frames
      .map((FrameTiming f) => f.rasterDuration.inMicroseconds / 1000)
      .toList();
  final int janky = frames
      .where((FrameTiming f) => f.totalSpan.inMilliseconds > 16)
      .length;
  double avg(List<double> xs) => xs.reduce((double a, double b) => a + b) / xs.length;
  double maxOf(List<double> xs) => xs.reduce((double a, double b) => a > b ? a : b);

  // ignore: avoid_print
  print(
    '[PERF] $label: frames=${frames.length} '
    'build avg=${avg(build).toStringAsFixed(1)}ms max=${maxOf(build).toStringAsFixed(1)}ms | '
    'raster avg=${avg(raster).toStringAsFixed(1)}ms max=${maxOf(raster).toStringAsFixed(1)}ms | '
    'jank(>16ms)=$janky',
  );
}
