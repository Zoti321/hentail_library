import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';

Future<T?> showTagDictionaryImportBusyDialog<T>({
  required BuildContext context,
  required String title,
  required String body,
  required Future<T?> Function() task,
  VoidCallback? onCancel,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _TagDictionaryImportBusyDialog<T>(
        title: title,
        body: body,
        task: task,
        onCancel: onCancel,
      );
    },
  );
}

class _TagDictionaryImportBusyDialog<T> extends StatefulWidget {
  const _TagDictionaryImportBusyDialog({
    required this.title,
    required this.body,
    required this.task,
    this.onCancel,
  });

  final String title;
  final String body;
  final Future<T?> Function() task;
  final VoidCallback? onCancel;

  @override
  State<_TagDictionaryImportBusyDialog<T>> createState() =>
      _TagDictionaryImportBusyDialogState<T>();
}

class _TagDictionaryImportBusyDialogState<T>
    extends State<_TagDictionaryImportBusyDialog<T>> {
  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      final T? result = await widget.task();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return HentaiDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.body,
            style: TextStyle(color: colorScheme.hentai.textSecondary),
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 4),
        ],
      ),
      actions: widget.onCancel == null
          ? <Widget>[]
          : <Widget>[
              TextButton(
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
                child: Text(context.l10n.commonCancel),
              ),
            ],
    );
  }
}
