import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_image_tile.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_submission_dialogs.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 投稿成员编辑：自本图集工作区增删成员并重排（含已排除图片）。
class ImageSetSubmissionEditorPage extends ConsumerStatefulWidget {
  const ImageSetSubmissionEditorPage({
    super.key,
    required this.libraryId,
    required this.imageSetId,
    required this.submission,
  });

  final String libraryId;
  final String imageSetId;
  final ImageSetSubmission submission;

  @override
  ConsumerState<ImageSetSubmissionEditorPage> createState() =>
      _ImageSetSubmissionEditorPageState();
}

class _ImageSetSubmissionEditorPageState
    extends ConsumerState<ImageSetSubmissionEditorPage> {
  ImageSetImagesKey get _imagesKey => (
    libraryId: widget.libraryId,
    imageSetId: widget.imageSetId,
  );

  ImageSetSubmission _resolveSubmission(List<ImageSetSubmission> all) {
    for (final ImageSetSubmission s in all) {
      if (s.submissionId == widget.submission.submissionId) {
        return s;
      }
    }
    return widget.submission;
  }

  Future<void> _rename(ImageSetSubmission submission) async {
    final AppLocalizations l10n = context.l10n;
    final String? name = await showImageSetSubmissionNameDialog(
      context: context,
      title: l10n.imageSetSubmissionRenameTitle,
      fieldLabel: l10n.imageSetSubmissionNameLabel,
      initialName: submission.name,
      requireNonEmptyName: true,
    );
    if (name == null || !mounted) {
      return;
    }
    await ref.read(imageSetRenameSubmissionCommandProvider)(
      widget.libraryId,
      submission.submissionId,
      name,
    );
  }

  Future<void> _delete(ImageSetSubmission submission) async {
    final bool confirmed = await showImageSetSubmissionDeleteConfirmDialog(
      context: context,
      submissionName: submission.name,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await ref.read(imageSetDeleteSubmissionCommandProvider)(
      widget.libraryId,
      submission.submissionId,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _removeMember(
    ImageSetSubmission submission,
    String imageId,
  ) async {
    await ref.read(imageSetRemoveSubmissionMembersCommandProvider)(
      widget.libraryId,
      submission.submissionId,
      <String>[imageId],
    );
  }

  Future<void> _persistReorder(
    ImageSetSubmission submission,
    List<String> orderedIds,
  ) async {
    await ref.read(imageSetReorderSubmissionMembersCommandProvider)(
      widget.libraryId,
      submission.submissionId,
      orderedIds,
    );
  }

  Future<void> _pickMembers(
    ImageSetSubmission submission,
    List<ImageSetImage> workspace,
  ) async {
    final Set<String> memberIds = submission.memberImageIds.toSet();
    final List<ImageSetImage> candidates = workspace
        .where((ImageSetImage i) => !memberIds.contains(i.imageSetImageId))
        .toList(growable: false);
    if (candidates.isEmpty) {
      return;
    }
    final List<String>? picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _SubmissionMemberPickerSheet(
        libraryId: widget.libraryId,
        candidates: candidates,
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) {
      return;
    }
    await ref.read(imageSetAddSubmissionMembersCommandProvider)(
      widget.libraryId,
      submission.submissionId,
      picked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;
    final AsyncValue<List<ImageSetSubmission>> submissionsAsync = ref.watch(
      imageSetSubmissionsProvider(_imagesKey),
    );
    final AsyncValue<List<ImageSetImage>> workspaceAsync = ref.watch(
      imageSetWorkspaceImagesProvider(_imagesKey),
    );

    return Scaffold(
      body: SafeArea(
        child: submissionsAsync.when(
          data: (List<ImageSetSubmission> submissions) {
            final ImageSetSubmission submission = _resolveSubmission(
              submissions,
            );
            return workspaceAsync.when(
              data: (List<ImageSetImage> workspace) {
                final Map<String, ImageSetImage> byId = <String, ImageSetImage>{
                  for (final ImageSetImage i in workspace) i.imageSetImageId: i,
                };
                final List<ImageSetImage> members = submission.memberImageIds
                    .map((String id) => byId[id])
                    .whereType<ImageSetImage>()
                    .toList(growable: false);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalInset,
                        vertical: theme.spacing.sm,
                      ),
                      child: Row(
                        children: <Widget>[
                          DetailHeaderBackButton(
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Text(
                              submission.name,
                              style: theme.typeScale.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Symbols.edit),
                            tooltip: l10n.imageSetSubmissionRenameTitle,
                            onPressed: () {
                              // ignore: discarded_futures
                              _rename(submission);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Symbols.delete,
                              color: theme.colorScheme.error,
                            ),
                            tooltip: l10n.commonDelete,
                            onPressed: () {
                              // ignore: discarded_futures
                              _delete(submission);
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                      child: M3EButton(
                        onPressed: candidatesAvailable(
                              submission,
                              workspace,
                            )
                            ? () {
                                // ignore: discarded_futures
                                _pickMembers(submission, workspace);
                              }
                            : null,
                        style: M3EButtonStyle.tonal,
                        icon: const Icon(Symbols.add),
                        label: Text(l10n.imageSetSubmissionAddMembers),
                      ),
                    ),
                    SizedBox(height: theme.spacing.md),
                    Expanded(
                      child: members.isEmpty
                          ? Center(child: Text(l10n.imageSetSubmissionMembersEmpty))
                          : _SubmissionMemberList(
                              libraryId: widget.libraryId,
                              members: members,
                              horizontalInset: horizontalInset,
                              onRemove: (String id) {
                                // ignore: discarded_futures
                                _removeMember(submission, id);
                              },
                              onReorder: (List<String> ordered) =>
                                  _persistReorder(submission, ordered),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace _) =>
                  Center(child: Text(appErrorMessage(error))),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) =>
              Center(child: Text(appErrorMessage(error))),
        ),
      ),
    );
  }

  static bool candidatesAvailable(
    ImageSetSubmission submission,
    List<ImageSetImage> workspace,
  ) {
    final Set<String> memberIds = submission.memberImageIds.toSet();
    return workspace.any(
      (ImageSetImage i) => !memberIds.contains(i.imageSetImageId),
    );
  }
}

class _SubmissionMemberList extends StatefulWidget {
  const _SubmissionMemberList({
    required this.libraryId,
    required this.members,
    required this.horizontalInset,
    required this.onRemove,
    required this.onReorder,
  });

  final String libraryId;
  final List<ImageSetImage> members;
  final double horizontalInset;
  final void Function(String imageId) onRemove;
  final Future<void> Function(List<String> orderedIds) onReorder;

  @override
  State<_SubmissionMemberList> createState() => _SubmissionMemberListState();
}

class _SubmissionMemberListState extends State<_SubmissionMemberList> {
  late List<ImageSetImage> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = List<ImageSetImage>.of(widget.members);
  }

  @override
  void didUpdateWidget(covariant _SubmissionMemberList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOrder(widget.members, _ordered)) {
      _ordered = List<ImageSetImage>.of(widget.members);
    }
  }

  bool _sameOrder(List<ImageSetImage> a, List<ImageSetImage> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].imageSetImageId != b[i].imageSetImageId) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final List<ImageSetImage> next = applyReorder(
      _ordered,
      oldIndex,
      newIndex,
    );
    setState(() => _ordered = next);
    await widget.onReorder(
      next.map((ImageSetImage i) => i.imageSetImageId).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);

    return ReorderableListView.builder(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalInset),
      itemCount: _ordered.length,
      onReorder: (int oldIndex, int newIndex) {
        // ignore: discarded_futures
        _onReorder(oldIndex, newIndex);
      },
      itemBuilder: (BuildContext context, int index) {
        final ImageSetImage image = _ordered[index];
        return ReorderableDragStartListener(
          key: ValueKey<String>(image.imageSetImageId),
          index: index,
          child: Padding(
            padding: EdgeInsets.only(bottom: theme.spacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ReorderExclude(
                  child: Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: theme.spacing.sm),
                ImageSetImageTile(
                  libraryId: widget.libraryId,
                  image: image,
                  compactWidth: 72,
                ),
                SizedBox(width: theme.spacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: theme.spacing.xs),
                    child: Text(
                      image.name,
                      style: theme.typeScale.bodyMedium.copyWith(
                        color: image.excluded
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: l10n.imageSetSubmissionRemoveMember,
                  onPressed: () => widget.onRemove(image.imageSetImageId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubmissionMemberPickerSheet extends StatefulWidget {
  const _SubmissionMemberPickerSheet({
    required this.libraryId,
    required this.candidates,
  });

  final String libraryId;
  final List<ImageSetImage> candidates;

  @override
  State<_SubmissionMemberPickerSheet> createState() =>
      _SubmissionMemberPickerSheetState();
}

class _SubmissionMemberPickerSheetState
    extends State<_SubmissionMemberPickerSheet> {
  final Set<String> _selected = <String>{};

  void _toggle(String id, bool? value) {
    setState(() {
      if (value == true) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(theme.spacing.md),
            child: Text(
              l10n.imageSetSubmissionPickMembersTitle,
              style: theme.typeScale.titleMedium,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.candidates.length,
              itemBuilder: (BuildContext context, int index) {
                final ImageSetImage image = widget.candidates[index];
                return CheckboxListTile(
                  value: _selected.contains(image.imageSetImageId),
                  onChanged: (bool? v) => _toggle(image.imageSetImageId, v),
                  title: Text(image.name),
                  subtitle: image.excluded
                      ? Text(l10n.imageSetDetailExcludedBadge)
                      : null,
                  secondary: ImageSetImageTile(
                    libraryId: widget.libraryId,
                    image: image,
                    compactWidth: 48,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(theme.spacing.md),
            child: M3EButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()),
              style: M3EButtonStyle.filled,
              label: Text(l10n.commonSave),
            ),
          ),
        ],
      ),
    );
  }
}