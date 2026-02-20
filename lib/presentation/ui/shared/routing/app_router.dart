import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/presentation/ui/desktop/routes/desktop_router.dart';
import 'package:hentai_library/presentation/ui/mobile/routes/mobile_router.dart';

final GoRouter appRouter = isDesktop ? desktopRouter : mobileRouter;
