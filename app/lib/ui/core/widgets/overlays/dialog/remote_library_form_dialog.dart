import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_toggle_field.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef RemoteLibraryFormResult = ({
  String rootUrl,
  String username,
  String password,
  bool allowHttp,
  bool passwordChanged,
});

Future<RemoteLibraryFormResult?> showRemoteLibraryFormDialog({
  required BuildContext context,
  LocalLibrary? existing,
}) {
  return showDialog<RemoteLibraryFormResult>(
    context: context,
    builder: (BuildContext dialogContext) =>
        RemoteLibraryFormDialog(existing: existing),
  );
}

class RemoteLibraryFormDialog extends HookConsumerWidget {
  const RemoteLibraryFormDialog({super.key, this.existing});

  final LocalLibrary? existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isEdit = existing != null;

    final ValueNotifier<String> rootUrl = useState(existing?.rootPath ?? '');
    final ValueNotifier<String> username = useState(existing?.username ?? '');
    final ValueNotifier<String> password = useState('');
    final ValueNotifier<bool> allowHttp = useState(existing?.allowHttp ?? false);
    final ValueNotifier<String?> urlError = useState<String?>(null);
    final ValueNotifier<String?> passwordError = useState<String?>(null);

    void submit() {
      final String url = rootUrl.value.trim();
      if (url.isEmpty) {
        urlError.value = l10n.remoteLibraryUrlRequired;
        return;
      }
      final bool httpScheme = url.toLowerCase().startsWith('http://');
      if (httpScheme && !allowHttp.value) {
        urlError.value = l10n.remoteLibraryHttpRequiresAllow;
        return;
      }
      if (!isEdit && password.value.isEmpty) {
        passwordError.value = l10n.remoteLibraryPasswordRequired;
        return;
      }
      Navigator.of(context).pop((
        rootUrl: url,
        username: username.value.trim(),
        password: password.value,
        allowHttp: allowHttp.value,
        passwordChanged: !isEdit || password.value.isNotEmpty,
      ));
    }

    return HentaiDialog(
      title: isEdit ? l10n.remoteLibraryEditTitle : l10n.remoteLibraryAddTitle,
      width: 480,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.remoteLibraryFormHint,
            style: TextStyle(fontSize: 13, color: cs.hentai.textSecondary),
          ),
          const SizedBox(height: 14),
          FluentTextField(
            labelText: l10n.remoteLibraryUrlLabel,
            hintText: l10n.remoteLibraryUrlHint,
            initialValue: rootUrl.value,
            isDense: true,
            errorText: urlError.value,
            keyboardType: TextInputType.url,
            onChanged: (String value) {
              rootUrl.value = value;
              urlError.value = null;
            },
          ),
          const SizedBox(height: 12),
          FluentTextField(
            labelText: l10n.remoteLibraryUsernameLabel,
            initialValue: username.value,
            isDense: true,
            onChanged: (String value) => username.value = value,
          ),
          const SizedBox(height: 12),
          FluentTextField(
            labelText: isEdit
                ? l10n.remoteLibraryPasswordEditLabel
                : l10n.remoteLibraryPasswordLabel,
            hintText: isEdit ? l10n.remoteLibraryPasswordKeepHint : null,
            isDense: true,
            obscureText: true,
            errorText: passwordError.value,
            onChanged: (String value) {
              password.value = value;
              passwordError.value = null;
            },
          ),
          const SizedBox(height: 12),
          FluentToggleField(
            labelText: l10n.remoteLibraryAllowHttpLabel,
            value: allowHttp.value,
            checkedLabel: l10n.remoteLibraryAllowHttpOn,
            uncheckedLabel: l10n.remoteLibraryAllowHttpOff,
            onChanged: (bool value) => allowHttp.value = value,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: submit,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(isEdit ? l10n.commonSave : l10n.commonAdd),
        ),
      ],
    );
  }
}
