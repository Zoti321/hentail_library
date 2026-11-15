import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/media/public/widgets.dart';
import 'package:hentai_library/features/resource_metadata/public/contracts.dart';
import 'package:hentai_library/features/resource_metadata/public/providers.dart';
import 'package:hentai_library/features/library_admin/public/providers.dart';
import 'package:hentai_library/features/app_settings/public.dart';

class ResourceMetadataMediaPreview extends StatelessWidget {
  const ResourceMetadataMediaPreview({super.key});
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      writebackGatewayProvider.overrideWithValue(_PreviewGateway()),
      librariesProvider.overrideWith(_PreviewLibraries.new),
      settingsProvider.overrideWith(_PreviewSettings.new),
    ],
    child: MediaPage(onEdit: (context, ref, id) async {}),
  );
}

class _PreviewLibraries extends LibrariesNotifier {
  @override
  Future<LibrariesState> build() async => const LibrariesState(libraries: []);
}

class _PreviewSettings extends SettingsNotifier {
  @override
  Future<AppSetting> build() async => AppSetting();
}

class _PreviewGateway implements WritebackGateway {
  @override
  Future<bool> isEnabled(String libraryId) async => true;
  @override
  Future<void> setEnabled(String libraryId, bool enabled) async {}
  @override
  Future<bool> processNext() async => false;
  @override
  Future<MediaResult> query({
    String? libraryId,
    String? state,
    required bool showR18,
    required int offset,
  }) async {
    final items =
        [
              'disabled',
              'pending',
              'processing',
              'completed',
              'failed',
              'unsupported',
            ]
            .where((value) => state == null || state == value)
            .map(
              (value) => (
                comicId: value,
                libraryId: 'local',
                libraryName: 'Local library',
                path: '/Comics/$value.cbz',
                title: '漫画资源 · $value',
                format: 'cbz',
                state: value,
                error: value == 'failed' ? 'Resource is read-only' : null,
                lastSuccessAt: value == 'completed'
                    ? DateTime.utc(2026, 11, 15)
                    : null,
                metadata: <String, String>{
                  'title': '漫画资源',
                  'authors': 'Author',
                  'languages': 'Japanese',
                },
              ),
            )
            .toList();
    return (items: items, total: items.length);
  }
}
