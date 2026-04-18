import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'panels/tag_management_panel.dart';

export 'panels/tag_management_panel.dart' show TagManagementPanel;

class TagManagementPage extends ConsumerWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TagManagementPanel();
  }
}
