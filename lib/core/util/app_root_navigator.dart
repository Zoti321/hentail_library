import 'package:flutter/material.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/ui/features/shell/views/routing/desktop_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/mobile_router.dart';

GlobalKey<NavigatorState> get appRootNavigatorKey =>
    isDesktop ? desktopRootNavigatorKey : mobileRootNavigatorKey;
