import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Viewport 对页列表 AsyncValue 的可观察结果（避免 loading/error 被当成空列表）。
sealed class ReaderViewportPages {
  const ReaderViewportPages();
}

final class ReaderViewportPagesLoading extends ReaderViewportPages {
  const ReaderViewportPagesLoading();
}

final class ReaderViewportPagesError extends ReaderViewportPages {
  const ReaderViewportPagesError(this.error);
  final Object error;
}

final class ReaderViewportPagesEmpty extends ReaderViewportPages {
  const ReaderViewportPagesEmpty();
}

final class ReaderViewportPagesReady extends ReaderViewportPages {
  const ReaderViewportPagesReady(this.pages);
  final List<ReaderPageImageData> pages;
}

ReaderViewportPages resolveReaderViewportPages(
  AsyncValue<List<ReaderPageImageData>> async,
) {
  if (async.hasError) {
    return ReaderViewportPagesError(async.error!);
  }
  final List<ReaderPageImageData>? pages = async.asData?.value;
  if (pages == null) {
    return const ReaderViewportPagesLoading();
  }
  if (pages.isEmpty) {
    return const ReaderViewportPagesEmpty();
  }
  return ReaderViewportPagesReady(pages);
}

/// 页列表失败 / 空 / 加载中的显式反馈（非空白 PageView）。
class ReaderViewportPagesFeedback extends StatelessWidget {
  const ReaderViewportPagesFeedback({super.key, required this.pages});

  final ReaderViewportPages pages;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.hentai.readerTextMuted;
    return switch (pages) {
      ReaderViewportPagesLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ReaderViewportPagesError() => Center(
        child: Text(
          context.l10n.readerViewportPagesFailed,
          style: TextStyle(fontSize: context.tokens.text.bodyLg, color: muted),
        ),
      ),
      ReaderViewportPagesEmpty() => Center(
        child: Text(
          context.l10n.readerNoImages,
          style: TextStyle(fontSize: context.tokens.text.bodyLg, color: muted),
        ),
      ),
      ReaderViewportPagesReady() => const SizedBox.expand(),
    };
  }
}
