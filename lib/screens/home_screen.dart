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
  bool _isFetchingBatches = false;
  bool _batchesFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ConnectionProvider>().startBackgroundMonitoring();
      }
    });
  }

  Future<void> _handleQRScan() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );
    
    if (result != null && mounted) {
      // Save session to provider
      await context.read<SessionProvider>().saveSession(result);
      
      // Start fetching batches
      setState(() {
        _isFetchingBatches = true;
        _batchesFetched = false;
      });
      
      // Simulate batch fetching (replace with actual API call)
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isFetchingBatches = false;
          _batchesFetched = true;
        });
      }
    }
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
              
              // Session Status Card with Batch Fetching Info
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
                                  'Session & Batch Status',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_isFetchingBatches)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else if (_batchesFetched)
                                Icon(
                                  Icons.table_chart,
                                  color: AppTheme.successColor,
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
                                      ? 'Session Active - Local Processing Ready'
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
                                  if (_isFetchingBatches)
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Fetching batch numbers...',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.warningColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (_batchesFetched)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                          color: AppTheme.successColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Batches fetched successfully • Local OCR enabled',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.successColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.offline_pin,
                                          size: 16,
                                          color: AppTheme.successColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Ready for batch data fetching',
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
              
              // Action Buttons
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // QR Scanner Button
                    SizedBox(
                      width: double.infinity,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: _handleQRScan,
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
                              'Start new session & fetch batches',
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
                    
                    // Batch Table Button
                    Consumer<SessionProvider>(
                      builder: (context, sessionProvider, child) {
                        final hasSession = sessionProvider.sessionId != null;
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: hasSession && _batchesFetched
                                ? () {
                                    // TODO: Navigate to batch table screen
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Batch table screen coming soon!'),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    );
                                  }
                                : null,
                            icon: Icon(
                              Icons.table_chart,
                              size: 20,
                              color: hasSession && _batchesFetched
                                  ? AppTheme.secondaryColor
                                  : AppTheme.textColor.withOpacity(0.3),
                            ),
                            label: Text(
                              'View Batch Table',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: hasSession && _batchesFetched
                                    ? AppTheme.secondaryColor
                                    : AppTheme.textColor.withOpacity(0.3),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: hasSession && _batchesFetched
                                    ? AppTheme.secondaryColor
                                    : AppTheme.borderColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Camera Button with Local OCR
                    Consumer<SessionProvider>(
                      builder: (context, sessionProvider, child) {
                        final hasSession = sessionProvider.sessionId != null;
                        final canCapture = hasSession && _batchesFetched;
                        return SizedBox(
                          width: double.infinity,
                          height: 70,
                          child: ElevatedButton(
                            onPressed: canCapture
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
                              backgroundColor: canCapture 
                                  ? AppTheme.successColor 
                                  : AppTheme.borderColor,
                              foregroundColor: canCapture
                                  ? AppTheme.primaryColor
                                  : AppTheme.textColor.withOpacity(0.5),
                              elevation: canCapture ? 6 : 2,
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
                                  canCapture 
                                      ? 'Local OCR + Direct submit' 
                                      : 'Requires session & batch data',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: canCapture 
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
