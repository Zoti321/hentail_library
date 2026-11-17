import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_image_filter_quality.dart';

void main() {
  test('Page image fidelity locks Reader sampling at FilterQuality.high', () {
    expect(kReaderPageFilterQuality, FilterQuality.high);
  });
}
