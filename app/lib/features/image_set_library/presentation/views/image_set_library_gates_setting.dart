import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Local Image set library edit：资源变更与托管布局闸门（不影响 Comic 库）。
class ImageSetLibraryGatesSetting extends ConsumerStatefulWidget {
  const ImageSetLibraryGatesSetting({super.key, required this.libraryId});

  final String libraryId;

  @override
  ConsumerState<ImageSetLibraryGatesSetting> createState() =>
      _ImageSetLibraryGatesSettingState();
}

class _ImageSetLibraryGatesSettingState
    extends ConsumerState<ImageSetLibraryGatesSetting> {
  bool _savingMutation = false;
  bool _savingManaged = false;
  String? _error;

  Future<void> _setMutation(bool enabled) async {
    if (_savingMutation || _savingManaged) {
      return;
    }
    setState(() {
      _savingMutation = true;
      _error = null;
    });
    try {
      await ref.read(imageSetSetResourceMutationCommandProvider)(
        widget.libraryId,
        enabled: enabled,
      );
      if (mounted) {
        ref.invalidate(imageSetLibraryGatesProvider(widget.libraryId));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.imageSetLibraryGatesSaveFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _savingMutation = false);
      }
    }
  }

  Future<void> _setManagedLayout(bool enabled) async {
    if (_savingMutation || _savingManaged) {
      return;
    }
    setState(() {
      _savingManaged = true;
      _error = null;
    });
    try {
      await ref.read(imageSetSetManagedLayoutCommandProvider)(
        widget.libraryId,
        enabled: enabled,
      );
      if (mounted) {
        ref.invalidate(imageSetLibraryGatesProvider(widget.libraryId));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.imageSetLibraryGatesSaveFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _savingManaged = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<ImageSetLibraryGates> gates = ref.watch(
      imageSetLibraryGatesProvider(widget.libraryId),
    );
    final bool busy = _savingMutation || _savingManaged;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        gates.when(
          skipLoadingOnReload: true,
          data: (ImageSetLibraryGates value) => Column(
            children: <Widget>[
              SettingsSwitchTile(
                title: Text(l10n.imageSetLibraryGateResourceMutationTitle),
                description: Text(l10n.imageSetLibraryGateResourceMutationHint),
                value: value.resourceMutation,
                enabled: !busy,
                onChanged: _setMutation,
              ),
              SettingsSwitchTile(
                title: Text(l10n.imageSetLibraryGateManagedLayoutTitle),
                description: Text(l10n.imageSetLibraryGateManagedLayoutHint),
                value: value.managedLayout,
                enabled: !busy,
                onChanged: _setManagedLayout,
              ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: M3EProgressIndicator.linear(),
          ),
          error: (Object _, StackTrace _) =>
              Text(l10n.imageSetLibraryGatesLoadFailed),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}