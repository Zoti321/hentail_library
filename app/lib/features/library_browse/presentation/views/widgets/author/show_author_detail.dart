import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/author_detail_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/author/author_detail_surface.dart';

Future<void> showAuthorDetail({
  required BuildContext context,
  required int authorId,
}) {
  return showAdaptiveFormSurfaceWidget<void>(
    context: context,
    surface: AuthorDetailSurface(authorId: authorId),
  );
}

Future<void> showAuthorDetailByName({
  required BuildContext context,
  required WidgetRef ref,
  required String name,
}) async {
  final int? authorId = await ref
      .read(authorDetailCommandsProvider)
      .idByName(name);
  if (authorId == null || !context.mounted) {
    return;
  }
  await showAuthorDetail(context: context, authorId: authorId);
}
