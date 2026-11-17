import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/image/catalog_image_filter_quality.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/app_comic_image.dart';

void main() {
  test('Tier C locks catalog sampling at Comic browse FilterQuality.medium', () {
    expect(kCatalogImageFilterQuality, FilterQuality.medium);
    expect(
      kCatalogImageFilterQuality,
      const AppComicImage(filePath: '').filterQuality,
    );
  });
}
