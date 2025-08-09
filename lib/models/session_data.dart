import 'batch_info.dart';

class SessionData {
  final String sessionId;
  final List<BatchInfo> batches;

  SessionData({required this.sessionId, required this.batches});
}
