import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_page_widgets.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';

void main() {
  group('libraryGridDelegateForTokens', () {
    test('returns tiered grid metrics', () {
      final AppThemeTokens tokens = buildAppTheme(Brightness.light)
          .extension<AppThemeTokens>()!;

      final SliverGridDelegateWithMaxCrossAxisExtent compactDelegate =
          libraryGridDelegateForTokens(tokens, LibraryLayoutTier.compact)
              as SliverGridDelegateWithMaxCrossAxisExtent;
      expect(compactDelegate.maxCrossAxisExtent, 168);
      expect(compactDelegate.crossAxisSpacing, 12);
      expect(compactDelegate.mainAxisSpacing, 12);

      final SliverGridDelegateWithMaxCrossAxisExtent expandedDelegate =
          libraryGridDelegateForTokens(tokens, LibraryLayoutTier.expanded)
              as SliverGridDelegateWithMaxCrossAxisExtent;
      expect(expandedDelegate.maxCrossAxisExtent, 200);
      expect(expandedDelegate.crossAxisSpacing, 16);
      expect(expandedDelegate.mainAxisSpacing, 16);
    });
  });
}
