// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:my_library/helpers/database_helper.dart';
import 'package:my_library/screens/main_wrapper.dart';
import 'package:my_library/services/book_service.dart';
import 'package:my_library/theme/app_theme.dart'; // Yeni tema dosyamızı import ediyoruz

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await DatabaseHelper.instance.database;

  runApp(
    ChangeNotifierProvider(
      create: (context) => BookService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() { _themeMode = themeMode; });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitaplığım',
      // === TEMA ATAMALARI GÜNCELLENDİ ===
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // ===================================
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: MainWrapper(changeTheme: changeTheme),
    );
  }
}