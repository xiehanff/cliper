import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../application/controllers/app_controller.dart';
import '../core/theme/app_theme.dart';
import '../presentation/pages/home_page.dart';

class CliperApp extends StatelessWidget {
  const CliperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        return MaterialApp(
          title: 'CLIPER',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeDataFor(controller.currentTheme),
          home: HomePage(
            onHeaderDragStart: () async {
              try {
                await windowManager.startDragging();
              } catch (_) {
                // Dragging requires window_manager to be initialized.
              }
            },
          ),
        );
      },
    );
  }
}
