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

  // First submission - image only (like web app initial capture)
  Map<String, dynamic> toInitialJson() => {
        'captureId': captureId,
        'sessionId': sessionId,
        'image': imageBase64,
      };

  // Final submission - with quantity (like web app final submit)
  Map<String, dynamic> toFinalJson() => {
        'quantity': quantity ?? '',
        'sessionId': sessionId,
        'captureId': captureId,
        'submitTimestamp': timestamp.millisecondsSinceEpoch,
      };
}
