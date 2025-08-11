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
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt,
              size: 32,
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(width: 12),
            const Text(
              'BatchMate',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
        actions: [
          // Connection Status Indicator
          Consumer<ConnectionProvider>(
            builder: (context, connectionProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: connectionProvider.status == ConnectionStatus.connected
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: connectionProvider.status == ConnectionStatus.connected
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectionProvider.status == ConnectionStatus.connected
                          ? Icons.wifi
                          : connectionProvider.status == ConnectionStatus.testing
                              ? Icons.sync
                              : Icons.wifi_off,
                      size: 16,
                      color: connectionProvider.status == ConnectionStatus.connected
                          ? AppTheme.successColor
                          : connectionProvider.status == ConnectionStatus.testing
                              ? AppTheme.warningColor
                              : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connectionProvider.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: connectionProvider.status == ConnectionStatus.connected
                            ? AppTheme.successColor
                            : connectionProvider.status == ConnectionStatus.testing
                                ? AppTheme.warningColor
                                : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: AppTheme.textColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebugScreen()),
            ),
            tooltip: 'Debug Logs',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card with Local OCR Info
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.offline_bolt,
                        size: 80,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to BatchMate',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Local OCR Processing • Offline Capable • Direct Submission',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan QR codes, capture images with local text extraction, and submit directly to backend',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Session Status Card with Local Storage Info
              Consumer<SessionProvider>(
                builder: (context, sessionProvider, child) {
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                sessionProvider.sessionId != null
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: sessionProvider.sessionId != null
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Session & Local Storage',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.storage,
                                color: AppTheme.secondaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: sessionProvider.sessionId != null
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: sessionProvider.sessionId != null
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sessionProvider.sessionId != null
                                      ? 'Session Active - Ready for Local Processing'
                                      : 'No Session - Scan QR to Start',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (sessionProvider.sessionId != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${sessionProvider.sessionId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textColor.withOpacity(0.7),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.offline_pin,
                                        size: 16,
                                        color: AppTheme.successColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Local OCR enabled • Data stored locally',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons with Enhanced Descriptions
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // QR Scanner Button
                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_scanner, size: 28),
                            const SizedBox(height: 4),
                            const Text(
                              'Scan QR Code',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Start new session',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Camera Button with Local OCR
                    Consumer<SessionProvider>(
                      builder: (context, sessionProvider, child) {
                        final hasSession = sessionProvider.sessionId != null;
                        return SizedBox(
                          width: double.infinity,
                          height: 70,
                          child: ElevatedButton(
                            onPressed: hasSession
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CameraScreen(),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasSession 
                                  ? AppTheme.successColor 
                                  : AppTheme.borderColor,
                              foregroundColor: hasSession
                                  ? AppTheme.primaryColor
                                  : AppTheme.textColor.withOpacity(0.5),
                              elevation: hasSession ? 6 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt, size: 28),
                                const SizedBox(height: 4),
                                const Text(
                                  'Capture & Process',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  hasSession ? 'Local OCR + Direct submit' : 'Requires session',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasSession 
                                        ? AppTheme.primaryColor.withOpacity(0.8)
                                        : AppTheme.textColor.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Connection Test Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Consumer<ConnectionProvider>(
                        builder: (context, connectionProvider, child) {
                          return OutlinedButton.icon(
                            onPressed: connectionProvider.status == ConnectionStatus.testing
                                ? null
                                : () => connectionProvider.testConnection(),
                            icon: connectionProvider.status == ConnectionStatus.testing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.wifi_find, size: 24),
                            label: Text(
                              connectionProvider.status == ConnectionStatus.testing
                                  ? 'Testing Connection...'
                                  : 'Test Backend Connection',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.secondaryColor,
                              side: BorderSide(color: AppTheme.secondaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Footer with Version Info
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.offline_bolt,
                          size: 16,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Local Processing Enabled',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Medha AI • BatchMate Mobile v2.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textColor.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
