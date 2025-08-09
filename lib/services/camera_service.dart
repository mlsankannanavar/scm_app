import 'dart:io';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    final rear = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => _cameras!.first);
    _controller = CameraController(
      rear,
      ResolutionPreset.max,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  CameraController? get controller => _controller;

  Future<File> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    final xFile = await _controller!.takePicture();
    return File(xFile.path);
  }

  Future<void> setZoom(double zoom) async {
    if (_controller == null) return;
    final minZoom = await _controller!.getMinZoomLevel();
    final maxZoom = await _controller!.getMaxZoomLevel();
    final clamped = zoom.clamp(minZoom, maxZoom);
    await _controller!.setZoomLevel(clamped);
  }

  void dispose() {
    _controller?.dispose();
  }
}
