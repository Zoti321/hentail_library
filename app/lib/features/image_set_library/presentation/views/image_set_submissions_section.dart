import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_submission_dialogs.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_submission_editor_page.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Detail「投稿」列表：创建入口 + 成员数摘要；点击进入成员编辑页。
class ImageSetSubmissionsSection extends ConsumerWidget {
  const ImageSetSubmissionsSection({
    super.key,
    required this.libraryId,
    required this.imageSet,
    required this.horizontalInset,
  });

  final String libraryId;
  final ImageSet imageSet;
  final double horizontalInset;

  ImageSetImagesKey get _key => (
    libraryId: libraryId,
    imageSetId: imageSet.imageSetId,
  );

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final String? name = await showImageSetSubmissionNameDialog(
      context: context,
      title: l10n.imageSetSubmissionCreateTitle,
      fieldLabel: l10n.imageSetSubmissionNameLabel,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await ref.read(imageSetCreateSubmissionCommandProvider)(
      libraryId,
      imageSet.imageSetId,
      name,
    );
  }

  void _openEditor(BuildContext context, ImageSetSubmission submission) {
  Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ImageSetSubmissionEditorPage(
          libraryId: libraryId,
          imageSetId: imageSet.imageSetId,
          submission: submission,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final AsyncValue<List<ImageSetSubmission>> submissions = ref.watch(
      imageSetSubmissionsProvider(_key),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        theme.spacing.lg,
        horizontalInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                l10n.imageSetDetailSubmissionsTitle,
                style: theme.typeScale.titleMedium,
              ),
              const Spacer(),
              M3EButton(
                onPressed: () {
                  // ignore: discarded_futures
                  _create(context, ref);
                },
                style: M3EButtonStyle.text,
                icon: const Icon(Symbols.add),
                label: Text(l10n.imageSetDetailSubmissionsCreate),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.sm),
          submissions.when(
            data: (List<ImageSetSubmission> list) {
              if (list.isEmpty) {
                return Text(
                  l10n.imageSetDetailSubmissionsEmpty,
                  style: theme.typeScale.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                children: list
                    .map(
                      (ImageSetSubmission s) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name),
                        subtitle: Text(
                          l10n.imageSetDetailSubmissionsMemberCount(
                            s.memberImageIds.length,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openEditor(context, s),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace _) =>
                Text(appErrorMessage(error)),
          ),
        ],
      ),
    );
  }
}