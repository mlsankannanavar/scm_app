import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../utils/image_utils.dart';
import '../models/capture_data.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sessionController = TextEditingController();
  final _cameraService = CameraService();
  final _api = ApiService();
  CameraController? _controller;
  String? _statusMessage;
  bool _busy = false;

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
    return 'cap-${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4().substring(0,8)}';
  }

  Future<void> _captureAndSubmit() async {
    final session = context.read<SessionProvider>().sessionId;
    if (session == null || session.isEmpty) {
      setState(() => _statusMessage = 'Set session first');
      return;
    }
    if (_busy) return;
    setState(() { _busy = true; _statusMessage = 'Capturing...'; });
    try {
      final file = await _cameraService.takePicture();
      final optimized = await optimizeImage(File(file.path));
      final captureId = _generateCaptureId();
      final capture = CaptureData(
        captureId: captureId,
        sessionId: session,
        imageBase64: optimized,
        timestamp: DateTime.now(),
      );
      await _api.submitImage(capture.toJson());
      setState(() => _statusMessage = 'Submitted $captureId');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    _sessionController.text = sessionProvider.sessionId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('BatchMate Phase 1')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sessionController,
                    decoration: const InputDecoration(labelText: 'Session ID'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => sessionProvider.saveSession(_sessionController.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          if (_controller == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: CameraPreview(_controller!),
            ),
          if (_statusMessage != null)
            Container(
              width: double.infinity,
              color: Colors.blue.shade100,
              padding: const EdgeInsets.all(8),
              child: Text(_statusMessage!),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _captureAndSubmit,
                    icon: const Icon(Icons.camera),
                    label: const Text('Capture & Submit'),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
