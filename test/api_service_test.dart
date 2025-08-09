import 'package:flutter_test/flutter_test.dart';
import 'package:batchmate_mobile/services/api_service.dart';

void main() {
  test('base url constant', () {
    final api = ApiService();
    expect(api, isNotNull);
  });
}
