import 'package:flutter/material.dart';
import 'package:hentai_library/features/image_set_library/presentation/routing/image_set_reader_route_args.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_reader_page.dart';

/// go_router 图集阅读落地页（路径 + query 已由路由解析）。
class ImageSetReaderRoutePage extends StatelessWidget {
  const ImageSetReaderRoutePage({super.key, required this.args});

  final ImageSetReaderRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return ImageSetReaderPage(entry: args.toEntry());
  }
}