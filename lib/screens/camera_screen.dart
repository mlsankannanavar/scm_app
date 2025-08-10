import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/connection_provider.dart';
import '../theme/app_theme.dart';
import '../services/camera_service.dart';
import '../utils/image_utils.dart';
import '../models/capture_data.dart';
import '../services/api_service.dart';
import 'package:uuid/uuid.dart';
import 'debug_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _cameraService = CameraService();
  final _api = ApiService();
  CameraController? _controller;
  bool _busy = false;
  String? _statusMessage;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.initialize();
    setState(() => _controller = _cameraService.controller);
  }

  String _generateCaptureId() {
    // Match exact web app format: 'cap-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecondsSinceEpoch % 1000000).toRadixString(36);
    return 'cap-$timestamp-$random';
  }

  Future<void> _captureImage() async {
    final session = context.read<SessionProvider>().sessionId;
    if (session == null || session.isEmpty) {
      if (mounted) {
        setState(() => _statusMessage = 'Please set session ID first');
      }
      DebugScreen.addLog('ERROR: No session ID set');
      return;
    }
    if (_busy) return;
    
    if (mounted) {
      setState(() {
        _busy = true;
        _statusMessage = 'Capturing image...';
      });
    }
    DebugScreen.addLog('CAPTURE: Started image capture for session: $session');
    
    try {
      print('Starting image capture...');
      DebugScreen.addLog('CAPTURE: Calling camera service...');
      final file = await _cameraService.takePicture();
      print('Image captured: ${file.path}');
      DebugScreen.addLog('CAPTURE: Image saved to ${file.path}');
      
      if (mounted) {
        setState(() => _statusMessage = 'Processing image...');
      }
      DebugScreen.addLog('CAPTURE: Starting image optimization...');
      final optimized = await optimizeImage(File(file.path));
      print('Image optimized, size: ${optimized.length} characters');
      DebugScreen.addLog('CAPTURE: Image optimized, base64 length: ${optimized.length}');
      
      final captureId = _generateCaptureId();
      DebugScreen.addLog('CAPTURE: Generated capture ID: $captureId');
      
      // Step 1: Submit initial image (like web app)
      if (mounted) {
        setState(() => _statusMessage = 'Sending image to server...');
      }
      DebugScreen.addLog('API: Submitting initial image (web app step 1)...');
      
      final initialCapture = CaptureData(
        captureId: captureId,
        sessionId: session,
        imageBase64: optimized,
        timestamp: DateTime.now(),
      );
      
      final initialResponse = await _api.submitImage(initialCapture.toInitialJson());
      DebugScreen.addLog('API: Initial image submission - Response: ${initialResponse.statusCode}');
      
      // Step 2: Get quantity from user
      if (mounted) {
        setState(() => _statusMessage = 'Enter quantity...');
      }
      DebugScreen.addLog('CAPTURE: Showing quantity dialog...');
      final quantity = await _showQuantityDialog();
      
      if (quantity != null) {
        // Step 3: Submit final data with quantity (like web app final submit)
        if (mounted) {
          setState(() => _statusMessage = 'Submitting final data...');
        }
        DebugScreen.addLog('CAPTURE: Quantity entered: ${quantity.isEmpty ? 'None' : quantity}');
        DebugScreen.addLog('API: Submitting final data with quantity (web app step 2)...');
        
        final finalCapture = CaptureData(
          captureId: captureId,
          sessionId: session,
          imageBase64: optimized,
          timestamp: DateTime.now(), // Fresh timestamp for final submission
          quantity: quantity.isEmpty ? null : quantity,
        );
        
        final finalResponse = await _api.submitImage(finalCapture.toFinalJson());
        DebugScreen.addLog('API: Final submission - Response: ${finalResponse.statusCode}');
        DebugScreen.addLog('API: Final response body: ${finalResponse.body}');
        
        if (mounted) {
          setState(() => _statusMessage = 'Success! ID: $captureId');
        }
        DebugScreen.addLog('CAPTURE: ✅ COMPLETE - Capture $captureId submitted successfully');
        
        // Auto-clear status after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _statusMessage = null);
          }
        });
      } else {
        if (mounted) {
          setState(() => _statusMessage = 'Capture cancelled');
        }
        DebugScreen.addLog('CAPTURE: User cancelled quantity input');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _statusMessage = null);
          }
        });
      }
    } catch (e) {
      print('Error during capture/submit: $e');
      DebugScreen.addLog('ERROR: Capture failed - ${e.toString()}');
      
      // Create user-friendly error messages
      String userMessage = 'Capture failed';
      if (e.toString().contains('TimeoutException')) {
        userMessage = 'Server timeout - please try again';
      } else if (e.toString().contains('SocketException')) {
        userMessage = 'Network error - check internet connection';
      } else if (e.toString().contains('Connection refused')) {
        userMessage = 'Server unavailable - try again later';
      } else if (e.toString().contains('POST /api/submit failed')) {
        userMessage = 'Upload failed - server may be busy';
      }
      
      if (mounted) {
        setState(() => _statusMessage = userMessage);
      }
      
      // Show error for longer time
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _statusMessage = null);
        }
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<String?> _showQuantityDialog() async {
    final TextEditingController quantityController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.inventory, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Enter Quantity'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter the quantity for this batch item:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g., 100',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                  suffixText: 'units',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Leave empty if quantity is not applicable',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(quantityController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller == null)
            const Center(child: CircularProgressIndicator())
          else
            Positioned.fill(
              child: CameraPreview(_controller!),
            ),
          
          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ),
                // Connection Status and Status Message
                Column(
                  children: [
                    // Connection Status
                    Consumer<ConnectionProvider>(
                      builder: (context, connectionProvider, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: connectionProvider.status == ConnectionStatus.connected
                                ? AppTheme.successColor.withOpacity(0.9)
                                : AppTheme.errorColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
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
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                connectionProvider.statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Toggle flash if needed
                    },
                    icon: const Icon(Icons.flash_auto, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
          
          // Zoom controls
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.25,
            bottom: MediaQuery.of(context).size.height * 0.25,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: _zoomLevel,
                  min: 1.0,
                  max: 5.0,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                  onChanged: (value) {
                    setState(() => _zoomLevel = value);
                    _cameraService.setZoom(value);
                  },
                ),
              ),
            ),
          ),
          
          // Zoom indicator
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_zoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          
          // Bottom capture section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button (placeholder)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.white, size: 24),
                  ),
                  
                  // Main capture button
                  GestureDetector(
                    onTap: _busy ? null : _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _busy ? Colors.grey : Colors.white,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _busy
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                              ),
                            )
                          : const Icon(Icons.camera, size: 40, color: Colors.black),
                    ),
                  ),
                  
                  // Settings button (placeholder)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
