import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/camera_service.dart';
import '../utils/image_utils.dart';
import '../models/capture_data.dart';
import '../services/api_service.dart';
import 'package:uuid/uuid.dart';

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
    return 'cap-${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4().substring(0, 8)}';
  }

  Future<void> _captureImage() async {
    final session = context.read<SessionProvider>().sessionId;
    if (session == null || session.isEmpty) {
      setState(() => _statusMessage = 'Set session first');
      return;
    }
    if (_busy) return;
    
    setState(() {
      _busy = true;
      _statusMessage = 'Capturing...';
    });
    
    try {
      final file = await _cameraService.takePicture();
      final optimized = await optimizeImage(File(file.path));
      
      // Show quantity input dialog
      final quantity = await _showQuantityDialog();
      
      if (quantity != null) {
        final captureId = _generateCaptureId();
        final capture = CaptureData(
          captureId: captureId,
          sessionId: session,
          imageBase64: optimized,
          timestamp: DateTime.now(),
          quantity: quantity.isEmpty ? null : quantity,
        );
        
        await _api.submitImage(capture.toJson());
        setState(() => _statusMessage = 'Submitted $captureId');
      } else {
        setState(() => _statusMessage = 'Cancelled');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _busy = false);
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
                if (_statusMessage != null)
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
