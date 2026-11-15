import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/resource_metadata/presentation/writeback_providers.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';

class WritebackSetting extends ConsumerStatefulWidget {
  const WritebackSetting({super.key, required this.libraryId});
  final String libraryId;
  @override
  ConsumerState<WritebackSetting> createState() => _WritebackSettingState();
}

class _WritebackSettingState extends ConsumerState<WritebackSetting> {
  bool _saving = false;
  String? _error;
  Future<void> _change(bool enabled) async {
    if (_saving) {
      return;
    }
    final l10n = context.l10n;
    if (enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.writebackConfirmTitle),
          content: Text(l10n.writebackDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.writebackEnable),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }
    final gateway = ref.read(writebackGatewayProvider);
    final revision = ref.read(writebackRevisionProvider.notifier);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await gateway.setEnabled(widget.libraryId, enabled);
      if (mounted) {
        revision.changed();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = l10n.writebackFailure);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(writebackEnabledProvider(widget.libraryId));
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        value.when(
          data: (enabled) => SettingsSwitchTile(
            title: Text(l10n.writebackTitle),
            description: Text(l10n.writebackDescription),
            value: enabled,
            enabled: !_saving,
            onChanged: _change,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => Text(l10n.writebackFailure),
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
