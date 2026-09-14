import 'package:flutter/widgets.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';

/// 将 Read session 打开失败映射为本地化分类文案。
String readSessionOpenFailureMessage(BuildContext context, Object error) {
  return readSessionOpenFailureMessageFor(context.l10n, error);
}

String readSessionOpenFailureMessageFor(AppLocalizations l10n, Object error) {
  final ReadSessionFailureKind kind = error is ReadSessionPageLoadException
      ? error.kind
      : ReadSessionFailureKind.loadFailed;
  return switch (kind) {
    ReadSessionFailureKind.resourceNotFound => l10n.readerOpenResourceNotFound,
    ReadSessionFailureKind.remoteUnreachable =>
      l10n.readerOpenRemoteUnreachable,
    ReadSessionFailureKind.remoteAuthFailed => l10n.readerOpenRemoteAuthFailed,
    ReadSessionFailureKind.timedOut => l10n.readerOpenTimedOut,
    ReadSessionFailureKind.invalidOrEmptyContent =>
      l10n.readerOpenInvalidContent,
    ReadSessionFailureKind.loadFailed => l10n.readerOpenLoadFailed,
  };
}
