import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';

/// Opens the shell-wide search dialog; submits navigate to [/searched].
Future<void> showGlobalSearchDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    routeSettings: const RouteSettings(name: 'global-search'),
    builder: (BuildContext dialogContext) => const _GlobalSearchDialog(),
  );
}

class _GlobalSearchDialog extends StatefulWidget {
  const _GlobalSearchDialog();

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String query = _controller.text.trim();
    if (query.isEmpty) {
      showInfoToast(context, context.l10n.librarySearchKeywordEmpty);
      return;
    }
    final String encodedQuery = Uri.encodeQueryComponent(query);
    Navigator.of(context).pop();
    appRouter.push('/searched?q=$encodedQuery');
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              _submit();
              return null;
            },
          ),
        },
        child: AlertDialog(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          contentPadding: EdgeInsets.fromLTRB(
            tokens.spacing.lg,
            tokens.spacing.md,
            tokens.spacing.lg,
            tokens.spacing.lg,
          ),
          title: Text(
            context.l10n.globalSearchTitle,
            style: TextStyle(
              fontSize: tokens.text.titleSm,
              fontWeight: FontWeight.w600,
              color: cs.hentai.textPrimary,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: CustomTextField(
              controller: _controller,
              autofocus: true,
              hintText: context.l10n.librarySearchHint,
              onSubmitted: (_) => _submit(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: _submit,
              child: Text(context.l10n.globalSearchSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
