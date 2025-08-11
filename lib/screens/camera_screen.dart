import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/connection_provider.dart';
import '../theme/app_theme.dart';
import '../services/camera_service.dart';
import '../services/local_ocr_service.dart';
import '../services/local_batch_database_service.dart';
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
    DebugScreen.addLog('MOBILE_OCR: Started local image capture for session: $session');
    
    try {
      print('🔍 Starting LOCAL OCR image capture...');
      DebugScreen.addLog('MOBILE_OCR: Calling camera service...');
      final file = await _cameraService.takePicture();
      print('📸 Image captured: ${file.path}');
      DebugScreen.addLog('MOBILE_OCR: Image saved to ${file.path}');
      
      // Step 1: LOCAL OCR Processing
      if (mounted) {
        setState(() => _statusMessage = 'Processing with local OCR...');
      }
      DebugScreen.addLog('MOBILE_OCR: Starting local OCR text extraction...');
      
      final ocrService = LocalOcrService();
      final extractedText = await ocrService.extractTextFromImage(File(file.path));
      print('🔍 LOCAL OCR extracted text: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...');
      DebugScreen.addLog('MOBILE_OCR: Extracted text length: ${extractedText.length} characters');
      
      // Step 2: Batch Number Matching
      if (mounted) {
        setState(() => _statusMessage = 'Finding batch matches...');
      }
      DebugScreen.addLog('MOBILE_OCR: Starting batch number matching...');
      
      final batchDb = LocalBatchDatabaseService();
      final sessionBatches = await batchDb.getBatchesForSession(session);
      final matchResult = await ocrService.findBestBatchMatch(extractedText, sessionBatches);
      
      if (matchResult.batchNumber.isNotEmpty) {
        DebugScreen.addLog('MOBILE_OCR: ✅ Batch matched: ${matchResult.batchNumber} (confidence: ${matchResult.confidence.toStringAsFixed(2)})');
        print('✅ Batch matched: ${matchResult.batchNumber}');
        
        // Step 3: Get quantity from user
        if (mounted) {
          setState(() => _statusMessage = 'Enter quantity for ${matchResult.batchNumber}...');
        }
        DebugScreen.addLog('MOBILE_OCR: Showing quantity dialog for batch: ${matchResult.batchNumber}');
        
        final quantity = await _showQuantityDialog(batchNumber: matchResult.batchNumber);
        
        if (quantity != null && quantity.isNotEmpty) {
          // Step 4: Submit ONLY the result to backend (not the image)
          if (mounted) {
            setState(() => _statusMessage = 'Submitting batch result...');
          }
          DebugScreen.addLog('MOBILE_OCR: Quantity entered: $quantity');
          DebugScreen.addLog('MOBILE_OCR: Submitting final result to backend...');
          
          final captureId = _generateCaptureId();
          final directSubmissionData = {
            'sessionId': session,
            'batchNumber': matchResult.batchNumber,
            'quantity': quantity,
            'directSubmission': true,
            'captureId': captureId,
            'confidence': matchResult.confidence,
            'extractedText': extractedText.substring(0, extractedText.length > 500 ? 500 : extractedText.length),
            'timestamp': DateTime.now().toIso8601String(),
            'source': 'mobile_local_ocr',
          };
          
          final response = await _api.submitDirectResult(directSubmissionData);
          DebugScreen.addLog('MOBILE_OCR: Direct submission - Response: ${response.statusCode}');
          DebugScreen.addLog('MOBILE_OCR: Response body: ${response.body}');
          
          // Step 5: Store locally and show success
          await batchDb.storeCaptureRecord(
            session, 
            matchResult.batchNumber, 
            quantity, 
            captureId,
            confidence: matchResult.confidence,
          );
          
          if (mounted) {
            setState(() => _statusMessage = '✅ Success: ${matchResult.batchNumber} (Qty: $quantity)');
            // Return the batch number to the calling screen
            Navigator.of(context).pop(matchResult.batchNumber);
          }
          DebugScreen.addLog('MOBILE_OCR: ✅ COMPLETE - Local OCR batch ${matchResult.batchNumber} processed successfully');
          
        } else {
          if (mounted) {
            setState(() => _statusMessage = 'Capture cancelled');
          }
          DebugScreen.addLog('MOBILE_OCR: User cancelled quantity input');
        }
      } else {
        // No batch match found
        DebugScreen.addLog('MOBILE_OCR: ❌ No batch number matched from extracted text');
        if (mounted) {
          setState(() => _statusMessage = 'No batch number found in image');
        }
        
        // Show extracted text to user for debugging
        await _showNoMatchDialog(extractedText);
      }
      
    } catch (e) {
      print('❌ LOCAL OCR Error: $e');
      DebugScreen.addLog('MOBILE_OCR: ❌ Error during local OCR processing: $e');
      if (mounted) {
        setState(() => _statusMessage = 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
      // Auto-clear status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _statusMessage = null);
        }
      });
    }
  }

  Future<String?> _showQuantityDialog({String? batchNumber}) async {
    final TextEditingController quantityController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text('Enter Quantity'),
                ],
              ),
              if (batchNumber != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Batch: $batchNumber',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Future<void> _showNoMatchDialog(String extractedText) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              const Text('No Batch Found'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No batch number could be identified in the captured image.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Extracted text:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  extractedText.isNotEmpty 
                      ? extractedText.substring(0, extractedText.length > 200 ? 200 : extractedText.length)
                      : 'No text detected',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tips: Ensure the batch label is clearly visible and well-lit.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Try Again'),
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
