import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../screens/debug_screen.dart';

enum ConnectionStatus { unknown, connected, disconnected, testing }

class ConnectionProvider with ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.unknown;
  DateTime? _lastChecked;
  Timer? _backgroundTimer;
  final ApiService _api = ApiService();
  
  ConnectionStatus get status => _status;
  DateTime? get lastChecked => _lastChecked;
  
  String get statusText {
    switch (_status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.testing:
        return 'Testing...';
      case ConnectionStatus.unknown:
        return 'Unknown';
    }
  }
  
  String get statusIcon {
    switch (_status) {
      case ConnectionStatus.connected:
        return '🟢';
      case ConnectionStatus.disconnected:
        return '🔴';
      case ConnectionStatus.testing:
        return '🟡';
      case ConnectionStatus.unknown:
        return '⚪';
    }
  }

  // Manual connection test
  Future<void> testConnection() async {
    _updateStatus(ConnectionStatus.testing);
    DebugScreen.addLog('CONNECTION: Manual test started');
    
    try {
      final isConnected = await _api.testConnectivity();
      _updateStatus(isConnected ? ConnectionStatus.connected : ConnectionStatus.disconnected);
      DebugScreen.addLog('CONNECTION: Manual test result - ${isConnected ? 'Connected' : 'Disconnected'}');
    } catch (e) {
      _updateStatus(ConnectionStatus.disconnected);
      DebugScreen.addLog('CONNECTION: Manual test failed - $e');
    }
  }

  // Start background monitoring (ping every 2 minutes)
  void startBackgroundMonitoring() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (_status != ConnectionStatus.testing) {
        await _backgroundCheck();
      }
    });
    DebugScreen.addLog('CONNECTION: Background monitoring started (2min intervals)');
  }

  // Stop background monitoring
  void stopBackgroundMonitoring() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    DebugScreen.addLog('CONNECTION: Background monitoring stopped');
  }

  // Background connectivity check (silent)
  Future<void> _backgroundCheck() async {
    try {
      final isConnected = await _api.testConnectivity();
      final newStatus = isConnected ? ConnectionStatus.connected : ConnectionStatus.disconnected;
      
      // Only update if status changed to avoid unnecessary UI updates
      if (newStatus != _status) {
        _updateStatus(newStatus);
        DebugScreen.addLog('CONNECTION: Background check - Status changed to ${statusText}');
      }
    } catch (e) {
      if (_status != ConnectionStatus.disconnected) {
        _updateStatus(ConnectionStatus.disconnected);
        DebugScreen.addLog('CONNECTION: Background check failed - $e');
      }
    }
  }

  void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _lastChecked = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    stopBackgroundMonitoring();
    super.dispose();
  }
}
