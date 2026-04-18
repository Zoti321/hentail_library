import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'panels/author_management_panel.dart';

export 'panels/author_management_panel.dart' show AuthorManagementPanel;

class AuthorManagementPage extends ConsumerWidget {
  const AuthorManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AuthorManagementPanel();
  }
}
