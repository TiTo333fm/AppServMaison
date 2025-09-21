import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/wake_on_lan/presentation/server_provider.dart';

void main() {
  runApp(const AppServMaisonApp());
}

class AppServMaisonApp extends StatelessWidget {
  const AppServMaisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ServerProvider(),
      child: MaterialApp(
        title: 'AppServMaison',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}

