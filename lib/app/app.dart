import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/routes/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final settingsAsync = ref.watch(settingsProvider);

          final themeMode = settingsAsync.maybeWhen(
            data: (data) => data.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            orElse: () => ThemeMode.light,
          );

          return MaterialApp.router(
            locale: const Locale('zh', 'CN'),
            title: 'hentai library',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
