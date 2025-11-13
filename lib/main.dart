import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screens.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Note App',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const LoginScreen(),
        );
      },
    );
  }
}