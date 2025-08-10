class StatusResponse {
  final String status;
  final String? batchNumber;
  final String? message;

  StatusResponse({
    required this.status,
    this.batchNumber,
    this.message,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) => StatusResponse(
        status: json['status'] ?? '',
        batchNumber: json['batchNumber'],
        message: json['message'],
      );
}
