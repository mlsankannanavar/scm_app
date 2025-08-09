class ApprovalData {
  final String captureId;
  final String sessionId;
  final String imageData; // base64
  final String itemName;
  final String matchedBatch;

  ApprovalData({
    required this.captureId,
    required this.sessionId,
    required this.imageData,
    required this.itemName,
    required this.matchedBatch,
  });
}
