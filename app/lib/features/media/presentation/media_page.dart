import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/library_admin/public/contracts.dart';
import 'package:hentai_library/features/library_admin/public/providers.dart';
import 'package:hentai_library/features/resource_metadata/public/contracts.dart';
import 'package:hentai_library/features/resource_metadata/public/providers.dart';
import 'package:hentai_library/features/resource_metadata/public/widgets.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';

typedef MediaEdit = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  String comicId,
);

final _mediaQueryProvider = FutureProvider.autoDispose
    .family<
      MediaResult,
      ({String? library, String? state, bool showR18, int offset})
    >((ref, query) {
      ref.watch(writebackRevisionProvider);
      return ref
          .watch(writebackGatewayProvider)
          .query(
            libraryId: query.library,
            state: query.state,
            showR18: query.showR18,
            offset: query.offset,
          );
    });

class MediaPage extends ConsumerStatefulWidget {
  const MediaPage({super.key, required this.onEdit});
  final MediaEdit onEdit;
  @override
  ConsumerState<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends ConsumerState<MediaPage> {
  String? _library;
  String? _state;
  int _offset = 0;
  Timer? _updates;
  @override
  void initState() {
    super.initState();
    _updates = Timer.periodic(const Duration(seconds: 5), _refresh);
  }

  void _refresh(Timer timer) {
    if (mounted) {
      ref.read(writebackRevisionProvider.notifier).changed();
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final libraries =
        ref
            .watch(librariesProvider)
            .asData
            ?.value
            .libraries
            .where((library) => library.kind == 'local')
            .toList() ??
        <LocalLibrary>[];
    final preferences = ref.watch(settingsProvider).asData?.value;
    final showR18 = preferences != null && !preferences.healthyMode;
    final result = ref.watch(
      _mediaQueryProvider((
        library: _library,
        state: _state,
        showR18: showR18,
        offset: _offset,
      )),
    );
    final layout = PageLayoutSpec.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mediaTitle)),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.horizontalInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mediaSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  DropdownButton<String>(
                    value:
                        libraries.any(
                          (library) => library.libraryId == _library,
                        )
                        ? _library
                        : '',
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.mediaAllLibraries),
                      ),
                      for (final library in libraries)
                        DropdownMenuItem(
                          value: library.libraryId,
                          child: Text(library.name),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _library = value == '' ? null : value;
                      _offset = 0;
                    }),
                  ),
                  DropdownButton<String>(
                    value: _state ?? '',
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.mediaAllStates),
                      ),
                      for (final state in [
                        'disabled',
                        'pending',
                        'processing',
                        'completed',
                        'failed',
                        'unsupported',
                      ])
                        DropdownMenuItem(
                          value: state,
                          child: Text(_stateLabel(l10n, state)),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _state = value == '' ? null : value;
                      _offset = 0;
                    }),
                  ),
                ],
              ),
            ),
            if (_library != null) WritebackSetting(libraryId: _library!),
            Expanded(
              child: result.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text(l10n.shellLoadFailed)),
                data: (page) => page.items.isEmpty
                    ? Center(child: Text(l10n.mediaEmpty))
                    : ListView.builder(
                        itemCount: page.items.length,
                        itemBuilder: (context, index) {
                          final item = page.items[index];
                          return Card(
                            key: ValueKey(item.comicId),
                            child: ListTile(
                              title: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${item.libraryName} · ${item.format.toUpperCase()}\n${_stateLabel(l10n, item.state)}${item.error == null ? '' : '\n${item.error}'}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _detail(item),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _offset == 0
                      ? null
                      : () => setState(
                          () => _offset = (_offset - 50).clamp(0, _offset),
                        ),
                  child: Text(l10n.mediaPrevious),
                ),
                Text('${_offset ~/ 50 + 1}'),
                TextButton(
                  onPressed:
                      result.asData == null ||
                          _offset + 50 >= result.asData!.value.total
                      ? null
                      : () => setState(() => _offset += 50),
                  child: Text(l10n.mediaNext),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _detail(MediaResource item) async {
    final l10n = context.l10n;
    final edit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.mediaResource}: ${item.path}'),
                Text(_stateLabel(l10n, item.state)),
                Text(
                  '${l10n.mediaLastSuccess}: ${item.lastSuccessAt?.toLocal().toString() ?? l10n.mediaNeverWritten}',
                ),
                if (item.error != null) Text(item.error!),
                const Divider(),
                for (final entry in item.metadata.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableText(
                      '${_fieldLabel(l10n, entry.key)}\n${entry.value}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.mediaEdit),
          ),
        ],
      ),
    );
    if (edit == true && mounted) {
      await widget.onEdit(context, ref, item.comicId);
      if (mounted) {
        ref.read(writebackRevisionProvider.notifier).changed();
      }
    }
  }
}

String _stateLabel(AppLocalizations l10n, String state) => switch (state) {
  'disabled' => l10n.writebackDisabled,
  'pending' => l10n.writebackPending,
  'processing' => l10n.writebackProcessing,
  'completed' => l10n.writebackCompleted,
  'failed' => l10n.writebackFailed,
  _ => l10n.writebackUnsupported,
};

String _fieldLabel(AppLocalizations l10n, String key) => switch (key) {
  'title' => l10n.formComicTitleLabel,
  'description' => l10n.formComicDescriptionLabel,
  'published_at' => l10n.formPublishedDateLabel,
  'authors' => l10n.metadataTabAuthors,
  'tags' => l10n.metadataTabTags,
  'languages' => l10n.formLanguagesLabel,
  'parodies' => l10n.metadataTabParodies,
  'characters' => l10n.metadataTabCharacters,
  'content_rating' => l10n.formAgeRestrictionLabel,
  _ => key,
};
