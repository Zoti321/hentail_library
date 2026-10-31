import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_controller.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_dictionary_import_controller.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/metadata_md3e_dialogs.dart';
import 'package:hentai_library/shared/domain/models/tag_dictionary_import_result.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/tag_name_editor_dialog.dart';

/// 重命名（沿用共享的名称编辑框）。
Future<void> renameNamedFacet(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
  String name,
) async {
  final l10n = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => TagNameEditorDialog(
      title: l10n.metadataRenameTitle(kind),
      labelText: l10n.metadataNewName,
      hintText: l10n.metadataRenameHint(kind),
      initialValue: name,
      shouldCloseOnUnchanged: true,
      onSubmit: (String value) async {
        await ref
            .read(namedFacetManagementControllerProvider(kind).notifier)
            .rename(name, value);
      },
    ),
  );
}

/// 删除单个命名元数据：先统计附着数量，再经 MD3E 确认框。
Future<void> deleteNamedFacet(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
  String name,
) async {
  final int count;
  try {
    count = await ref
        .read(namedFacetManagementControllerProvider(kind).notifier)
        .countAttachments(name);
  } catch (error) {
    if (context.mounted) {
      showErrorToast(context, error);
    }
    return;
  }
  if (!context.mounted) {
    return;
  }
  final bool confirmed = await showMetadataMd3eDeleteFacetDialog(
    context: context,
    name: name,
    attachmentCount: count,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    await ref
        .read(namedFacetManagementControllerProvider(kind).notifier)
        .delete(name);
    if (context.mounted) {
      showSuccessToast(context, context.l10n.metadataDeletedToast(kind));
    }
  } catch (error) {
    if (context.mounted) {
      showErrorToast(context, error);
    }
  }
}

/// 从网络导入标签词典；成功返回结果，取消 / 失败返回 null。
Future<TagDictionaryImportResult?> importTagDictionary(
  BuildContext context,
  WidgetRef ref, {
  required String url,
}) {
  final controller = ref.read(tagDictionaryImportControllerProvider.notifier);
  return showMetadataMd3eTagDictionaryImportDialog(
    context: context,
    onCancel: controller.cancel,
    importFromNetwork: ({void Function(int, int)? onDownloadProgress}) =>
        controller.importFromNetwork(
          url: url,
          onDownloadProgress: onDownloadProgress,
        ),
  );
}
