import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/session_provider.dart';
import 'providers/connection_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const BatchMateApp());
}

class BatchMateApp extends StatelessWidget {
  const BatchMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()..loadSavedSession()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
      ],
      child: MaterialApp(
        title: 'BatchMate',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
