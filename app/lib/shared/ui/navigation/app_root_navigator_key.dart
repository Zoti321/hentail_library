import 'package:flutter/material.dart';

/// 根 Navigator 的 GlobalKey（壳层与 feature 共享：需要无 context 的 root 弹层定位）。
///
/// 真源留 shared/ui：`app_settings` 等 feature 需要它，而 `core/**` 不得
/// import `features/**`（ADR-0045）。
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>();
