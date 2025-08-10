import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  static final List<String> _logs = [];
  
  static void addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > 100) {
      _logs.removeRange(100, _logs.length);
    }
  }
  
  static void clearLogs() {
    _logs.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                clearLogs();
              });
            },
            icon: const Icon(Icons.clear_all),
          ),
          IconButton(
            onPressed: () {
              final allLogs = _logs.join('\n');
              Clipboard.setData(ClipboardData(text: allLogs));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(
              child: Text(
                'No logs yet.\nPerform actions in the app to see debug information.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log.toLowerCase().contains('error') || 
                               log.toLowerCase().contains('failed') ||
                               log.toLowerCase().contains('exception');
                final isSuccess = log.toLowerCase().contains('success') || 
                                 log.toLowerCase().contains('submitted');
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: isError 
                      ? Colors.red.shade50 
                      : isSuccess 
                          ? Colors.green.shade50 
                          : Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isError 
                            ? Colors.red.shade800 
                            : isSuccess 
                                ? Colors.green.shade800 
                                : Colors.blue.shade800,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
