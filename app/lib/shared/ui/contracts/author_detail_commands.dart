import 'package:flutter/widgets.dart';

typedef OpenAuthorByIdCommand = Future<void> Function(
  BuildContext context,
  int authorId,
);
typedef OpenAuthorByNameCommand = Future<void> Function(
  BuildContext context,
  String name,
);
