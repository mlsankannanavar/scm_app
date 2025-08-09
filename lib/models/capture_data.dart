class CaptureData {
  final String captureId;
  final String sessionId;
  final String imageBase64;
  final DateTime timestamp;
  final String? quantity;

  CaptureData({
    required this.captureId,
    required this.sessionId,
    required this.imageBase64,
    required this.timestamp,
    this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'captureId': captureId,
        'sessionId': sessionId,
        'image': imageBase64,
        'submitTimestamp': timestamp.millisecondsSinceEpoch,
        if (quantity != null) 'quantity': quantity,
      };
}
