import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/session_provider.dart';
import 'screens/home_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'BatchMate',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}
