import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/connection_provider.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';
import 'qr_scanner_screen.dart';
import 'debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ConnectionProvider>().startBackgroundMonitoring();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BatchMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebugScreen()),
            ),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer<SessionProvider>(
                builder: (_, sp, __) => Text(
                  sp.sessionId == null ? 'No Session' : 'Session: ${sp.sessionId}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                ),
                child: const Text('Scan QR'),
              ),
              const SizedBox(height: 12),
              Consumer<SessionProvider>(
                builder: (_, sp, __) => ElevatedButton(
                  onPressed: sp.sessionId == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CameraScreen()),
                          ),
                  child: const Text('Capture Image'),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<ConnectionProvider>(
                builder: (_, cp, __) => ElevatedButton(
                  onPressed: cp.status == ConnectionStatus.testing ? null : () => cp.testConnection(),
                  child: Text(cp.statusText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
