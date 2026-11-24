import 'package:flutter_test/flutter_test.dart';
import 'package:opportunet/home_feed.dart';

void main() {
  final now = DateTime(2026, 11, 24, 18, 30);

  test('daysUntil counts calendar days, ignoring time of day', () {
    expect(daysUntil(DateTime(2026, 11, 24), now: now), 0);
    expect(daysUntil(DateTime(2026, 11, 25, 9), now: now), 1);
    expect(daysUntil(DateTime(2026, 12, 2), now: now), 8);
    expect(daysUntil(DateTime(2026, 11, 23, 23, 59), now: now), -1);
  });
}
