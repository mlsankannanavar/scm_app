/// Model for local batch data downloaded from server for offline OCR processing
class LocalBatchData {
  final String batchNumber;
  final String? expiryDate;
  final String? itemName;

  LocalBatchData({
    required this.batchNumber,
    this.expiryDate,
    this.itemName,
  });

  factory LocalBatchData.fromJson(Map<String, dynamic> json) {
    return LocalBatchData(
      batchNumber: json['batch_no'] ?? json['batchNumber'] ?? '',
      expiryDate: json['expiry_date'] ?? json['expiryDate'],
      itemName: json['item_name'] ?? json['itemName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batchNumber': batchNumber,
      'expiryDate': expiryDate,
      'itemName': itemName,
    };
  }

  @override
  String toString() {
    return 'LocalBatchData(batchNumber: $batchNumber, expiryDate: $expiryDate, itemName: $itemName)';
  }
}

/// Session batch data containing all batches for a session
class SessionBatchData {
  final String sessionId;
  final Map<String, LocalBatchData> batches;
  final DateTime downloadedAt;
  final int totalBatches;

  SessionBatchData({
    required this.sessionId,
    required this.batches,
    required this.downloadedAt,
    required this.totalBatches,
  });

  factory SessionBatchData.fromServerResponse(String sessionId, Map<String, dynamic> response) {
    final filteredBatches = response['filteredBatches'] as Map<String, dynamic>? ?? {};
    final Map<String, LocalBatchData> batches = {};

    for (final entry in filteredBatches.entries) {
      final batchNumber = entry.key;
      final batchData = entry.value as Map<String, dynamic>;
      
      batches[batchNumber] = LocalBatchData(
        batchNumber: batchNumber,
        expiryDate: batchData['expiry_date'],
        itemName: batchData['item_name'],
      );
    }

    return SessionBatchData(
      sessionId: sessionId,
      batches: batches,
      downloadedAt: DateTime.now(),
      totalBatches: response['totalBatches'] ?? batches.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'batches': batches.map((key, value) => MapEntry(key, value.toJson())),
      'downloadedAt': downloadedAt.toIso8601String(),
      'totalBatches': totalBatches,
    };
  }

  @override
  String toString() {
    return 'SessionBatchData(sessionId: $sessionId, totalBatches: $totalBatches, downloadedAt: $downloadedAt)';
  }
}

/// Match result from local OCR processing
class LocalMatchResult {
  final String? matchedBatch;
  final double? confidence;
  final String? expiryDate;
  final String? itemName;
  final bool isExactMatch;
  final List<String> candidateBatches;

  LocalMatchResult({
    this.matchedBatch,
    this.confidence,
    this.expiryDate,
    this.itemName,
    this.isExactMatch = false,
    this.candidateBatches = const [],
  });

  bool get hasMatch => matchedBatch != null && matchedBatch!.isNotEmpty;

  @override
  String toString() {
    return 'LocalMatchResult(matchedBatch: $matchedBatch, confidence: $confidence, isExactMatch: $isExactMatch)';
  }
}
