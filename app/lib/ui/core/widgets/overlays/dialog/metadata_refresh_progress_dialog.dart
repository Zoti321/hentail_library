import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/terminal_spinner.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:hentai_library/ui/features/shell/state/metadata_refresh_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const double _kDialogWidth = 420;
const double _kDialogRadius = 4;

/// Series 元数据刷新进度（不可取消；结束后点确定关闭）。
class MetadataRefreshProgressDialog extends ConsumerWidget {
  const MetadataRefreshProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final MetadataRefreshState state = ref.watch(
      metadataRefreshControllerProvider,
    );
    final RefreshSeriesProgress? progress = state.seriesProgress;
    final bool done = !state.running;
    final bool showError = state.error != null;

    return HentaiDialog(
      title: l10n.refreshMetadataSeriesDialogTitle,
      width: _kDialogWidth,
      borderRadius: _kDialogRadius,
      backgroundColor: cs.surface,
      showFooterDivider: false,
      scrollableContent: false,
      contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: showError
            ? Text(
                state.error!,
                style: TextStyle(color: cs.error, fontSize: 13),
              )
            : Row(
                children: <Widget>[
                  if (!done) ...<Widget>[
                    const TerminalSpinner(size: 18),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      done
                          ? l10n.refreshMetadataSeriesDone(
                              state.seriesResult?.succeeded ??
                                  progress?.succeeded ??
                                  0,
                              state.seriesResult?.failed ??
                                  progress?.failed ??
                                  0,
                            )
                          : l10n.refreshMetadataSeriesProgress(
                              progress?.current ?? 0,
                              progress?.total ?? 0,
                            ),
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.hentai.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: done
          ? <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kDialogRadius),
                  ),
                ),
                child: Text(
                  showError ? l10n.commonClose : l10n.commonOk,
                ),
              ),
            ]
          : const <Widget>[],
    );
  }
}

Future<void> showMetadataRefreshProgressDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => const MetadataRefreshProgressDialog(),
  );
}
