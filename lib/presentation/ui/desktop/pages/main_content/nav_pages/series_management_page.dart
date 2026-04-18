import 'package:flutter/material.dart';

import 'panels/series_management_panel.dart';

export 'panels/series_management_panel.dart' show SeriesManagementPanel;

class SeriesManagementPage extends StatelessWidget {
  const SeriesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SeriesManagementPanel();
  }
}
