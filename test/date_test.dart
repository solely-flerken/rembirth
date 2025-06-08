import 'package:flutter_test/flutter_test.dart';
import 'package:rembirth/util/date_util.dart';

void main() {
  group('daysUntilNextBirthday', () {
    test('returns 0 if today is the birthday', () {
      final today = DateTime.now();
      final result = DateUtil.daysUntilDate(today, today);
      expect(result, 0);
    });

    test('returns correct days if birthday is in 10 days', () {
      final today = DateTime.now();
      final future = today.add(Duration(days: 10));
      final result = DateUtil.daysUntilDate(today, future);
      expect(result, 10);
    });

    test('returns correct days if birthday was 10 days ago', () {
      final today = DateTime.now();
      final past = today.subtract(Duration(days: 10));
      final result = DateUtil.daysUntilDate(today, past);
      expect(result, 365 - 10);
    });
  });
}
