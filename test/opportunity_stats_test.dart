import 'package:flutter_test/flutter_test.dart';
import 'package:opportunet/opportunity_stats.dart';

void main() {
  test('tbilisiDay uses UTC+4', () {
    expect(tbilisiDay(DateTime.utc(2026, 11, 24, 21)), '2026-11-25');
    expect(tbilisiDay(DateTime.utc(2026, 11, 24, 19, 59)), '2026-11-24');
  });

  test('event id matches the rule', () {
    expect(
      statEventId('u1', StatEvent.save, 'olympiads', 'abc', '2026-11-24'),
      'u1_save_olympiads_abc_2026-11-24',
    );
  });

  test('sumStatDays adds days in the window only', () {
    final totals = sumStatDays({
      '2026-11-10': {'view': 5},
      '2026-11-20': {'view': 2, 'save': 1},
      '2026-11-24': {'view': 1, 'share': 3},
    }, '2026-11-18');
    expect(totals, {'view': 3, 'save': 1, 'share': 3});
  });
}
