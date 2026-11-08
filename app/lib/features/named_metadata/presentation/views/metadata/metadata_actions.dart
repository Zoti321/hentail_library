import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_dictionary_import_view_model.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/metadata_dialogs.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata/patterns/management_rename_entity_dialog.dart';
import 'package:hentai_library/features/named_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/shared/ui/widgets/feedback/app_snackbar.dart';

/// 重命名（M3E dialog + [ManagementEntityNameField]）。
Future<void> renameNamedFacet(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
  String name,
) {
  return showManagementRenameEntityDialog(
    context: context,
    facet: kind,
    initialName: name,
    onRename: (String value) => ref
        .read(namedFacetManagementViewModelProvider(kind).notifier)
        .rename(name, value),
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
        .read(namedFacetManagementViewModelProvider(kind).notifier)
        .countAttachments(name);
  } catch (error) {
    if (context.mounted) {
      showErrorSnackbar(context, error);
    }
    return;
  }
  if (!context.mounted) {
    return;
  }
  final bool confirmed = await showMetadataDeleteFacetDialog(
    context: context,
    name: name,
    attachmentCount: count,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    await ref
        .read(namedFacetManagementViewModelProvider(kind).notifier)
        .delete(name);
    if (context.mounted) {
      showSuccessSnackbar(context, context.l10n.metadataDeletedToast(kind));
    }
  } catch (error) {
    if (context.mounted) {
      showErrorSnackbar(context, error);
    }
  }
}

/// 从网络导入标签词典；成功返回结果，取消 / 失败返回 null。
Future<TagDictionaryImportResult?> importTagDictionary(
  BuildContext context,
  WidgetRef ref, {
  required String url,
}) {
  final AppLocalizations l10n = context.l10n;
  final TagDictionaryImportViewModel viewModel = ref.read(
    tagDictionaryImportViewModelProvider.notifier,
  );
  return showMetadataTagDictionaryImportDialog(
    context: context,
    onCancel: viewModel.cancel,
    bodyText: l10n.metadataImportTagDictionaryDialogBody,
    runImport: ({void Function(int, int)? onDownloadProgress}) => viewModel
        .importFromNetwork(url: url, onDownloadProgress: onDownloadProgress),
  );
}

/// 从本地 JSON 文件导入标签词典（管理页更多菜单入口）。
Future<void> importTagDictionaryFromFile(
  BuildContext context,
  WidgetRef ref,
) async {
  final AppLocalizations l10n = context.l10n;
  final FilePickerResult? picked = await FilePicker.pickFiles(
    dialogTitle: l10n.metadataImportTagDictionaryPickDialogTitle,
    type: FileType.custom,
    allowedExtensions: const <String>['json'],
    withData: true,
  );
  if (picked == null || picked.files.isEmpty || !context.mounted) {
    return;
  }

  final PlatformFile file = picked.files.single;
  final Uint8List? bytes = await _readPickedJsonBytes(file);
  if (bytes == null || bytes.isEmpty) {
    if (context.mounted) {
      showErrorSnackbar(context, l10n.metadataImportTagDictionaryInvalidFile);
    }
    return;
  }
  if (!context.mounted) {
    return;
  }

  final TagDictionaryImportViewModel viewModel = ref.read(
    tagDictionaryImportViewModelProvider.notifier,
  );
  final TagDictionaryImportResult? result =
      await showMetadataTagDictionaryImportDialog(
        context: context,
        onCancel: viewModel.cancel,
        bodyText: l10n.metadataImportTagDictionaryDialogBodyLocal,
        runImport: ({void Function(int, int)? onDownloadProgress}) =>
            viewModel.importFromBytes(bytes),
      );
  if (!context.mounted) {
    return;
  }
  if (result == null) {
    final String? error = ref.read(tagDictionaryImportViewModelProvider).error;
    if (error != null && error.isNotEmpty) {
      showErrorSnackbar(context, error);
    }
    return;
  }
  showSuccessSnackbar(
    context,
    l10n.metadataImportTagDictionarySummary(
      result.added,
      result.skippedExisting,
      result.skippedFilteredOrEmptyOrDedupe,
    ),
  );
}

Future<Uint8List?> _readPickedJsonBytes(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return Uint8List.fromList(file.bytes!);
  }
  final String? path = file.path;
  if (path == null || path.isEmpty) {
    return null;
  }
  try {
    return await File(path).readAsBytes();
  } catch (_) {
    return null;
  }
}
