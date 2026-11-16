import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/presentation/author/view_models/author_detail_notifier.dart';
import 'package:hentai_library/shared/ui/contracts/author_detail_commands.dart';
import 'package:hentai_library/shared/ui/navigation/app_navigator_context.dart';

OpenAuthorByIdCommand createOpenAuthorByIdCommand(Ref ref) =>
    (context, id) => Future<void>.sync(() {
      if (context.mounted) {
        appNavigatorOf(context).pushAuthorDetail(id);
      }
    });
OpenAuthorByNameCommand createOpenAuthorByNameCommand(Ref ref) =>
    (context, name) async {
      final id = await ref.read(authorDetailCommandsProvider).idByName(name);
      if (id != null && context.mounted) {
        appNavigatorOf(context).pushAuthorDetail(id);
      }
    };
