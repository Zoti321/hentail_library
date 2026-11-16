import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/media/public/widgets.dart';
import 'package:hentai_library/features/resource_metadata/public/contracts.dart';
import 'package:hentai_library/features/resource_metadata/public/providers.dart';
import 'package:hentai_library/features/library_admin/public/providers.dart';
import 'package:hentai_library/features/library_admin/public/contracts.dart';
import 'package:hentai_library/features/app_settings/public.dart';

import '../preview/md3e_library_edit_preview_data.dart';

class ResourceMetadataMediaPreview extends StatelessWidget {
  const ResourceMetadataMediaPreview({super.key});
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      writebackGatewayProvider.overrideWithValue(_PreviewGateway()),
      // ignore: scoped_providers_should_specify_dependencies
      librariesProvider.overrideWith(_PreviewLibraries.new),
      // ignore: scoped_providers_should_specify_dependencies
      settingsProvider.overrideWith(_PreviewSettings.new),
    ],
    child: const MediaPage(),
  );
}

class _PreviewLibraries extends LibrariesNotifier {
  @override
  Future<LibrariesState> build() async {
    final library = LibraryEditPreviewData.sampleLocalLibrary;
    return LibrariesState(
      libraries: [
        library,
        (
          libraryId: 'local-2',
          kind: 'local',
          catalogKind: 'comic',
          rootPath: '/Comics',
          name: '本地漫画库',
          enabledResourceFormatCategories: ResourceFormatCategory.all,
          username: '',
          allowHttp: false,
          scanOnStartup: false,
          scanInterval: ScanInterval.disabled,
          pinned: false,
          sidebarOrder: 1,
        ),
      ],
    );
  }
}

class _PreviewSettings extends SettingsNotifier {
  @override
  Future<AppSetting> build() async => AppSetting();
}

class _PreviewGateway implements WritebackGateway {
  final Map<String, bool> _enabled = {'lab-local-1': true};
  @override
  Future<bool> isEnabled(String libraryId) async =>
      _enabled[libraryId] ?? false;
  @override
  Future<void> setEnabled(String libraryId, bool enabled) async =>
      _enabled[libraryId] = enabled;
  @override
  Future<bool> processNext() async => false;
  @override
  Future<MediaOverview> overview({required bool showR18}) async => (
    total: 1280,
    disabled: 320,
    pending: 104,
    processing: 1,
    completed: 842,
    failed: 5,
    unsupported: 8,
    localLibraries: 2,
    enabledLibraries: _enabled.values.where((enabled) => enabled).length,
  );
}
