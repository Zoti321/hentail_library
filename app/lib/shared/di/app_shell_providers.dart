import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/ui/shell/md3e_app_shell_slot.dart';

/// 标题栏下方壳层级反馈 widget 列表（ADR-0027；owner 经 bootstrap 注入）。
typedef AppShellFeedbackBelowTitleBarFactory = List<Widget> Function();

/// MD3E 导航槽组装（需要 [WidgetRef] 读库状态；bootstrap 注入 owner 实现）。
typedef Md3eAppShellNavigationSlotAssembly =
    Md3eAppShellNavigationSlot Function(BuildContext context, WidgetRef ref);

final Provider<VoidCallback> appShellOpenNavigationDrawerProvider =
    Provider<VoidCallback>(
      (Ref ref) => throw UnimplementedError(
        'appShellOpenNavigationDrawerProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<AppShellFeedbackBelowTitleBarFactory>
appShellFeedbackBelowTitleBarFactoryProvider =
    Provider<AppShellFeedbackBelowTitleBarFactory>(
      (Ref ref) => throw UnimplementedError(
        'appShellFeedbackBelowTitleBarFactoryProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<Md3eAppShellNavigationSlotAssembly>
md3eAppShellNavigationSlotAssemblyProvider =
    Provider<Md3eAppShellNavigationSlotAssembly>(
      (Ref ref) => throw UnimplementedError(
        'md3eAppShellNavigationSlotAssemblyProvider 未注入，请在 bootstrap 中 override',
      ),
    );
