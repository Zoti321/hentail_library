import 'package:flutter/material.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart'
    show appRootNavigatorKey;

export 'package:hentai_library/ui/features/shell/views/routing/app_router.dart'
    show appRootNavigatorKey;

/// 应用根 [NavigatorState]，供 overlay / toast 等使用。
GlobalKey<NavigatorState> get rootNavigatorKey => appRootNavigatorKey;
