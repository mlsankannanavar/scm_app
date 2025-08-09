class BatchInfo {
  final String batchNumber;
  final DateTime? expiryDate;

  BatchInfo({required this.batchNumber, this.expiryDate});

  factory BatchInfo.fromJson(Map<String, dynamic> json) => BatchInfo(
        batchNumber: json['batchNumber'] ?? json['batch_number'] ?? '',
        expiryDate: json['expiryDate'] != null
            ? DateTime.tryParse(json['expiryDate'])
            : null,
      );
}
