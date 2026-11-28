import 'package:flutter_test/flutter_test.dart';
import 'package:opportunet/home_feed.dart';

void main() {
  final now = DateTime(2026, 11, 24);

  List<String> rank(List<Map<String, dynamic>> items,
      {int? age, Set<String> interests = const {}}) {
    items.sort((a, b) =>
        compareForYou(a, b, age: age, interests: interests, now: now));
    return [for (final item in items) item['title'] as String];
  }

  test('ageFits reads ranges, plus and single ages', () {
    expect(ageFits('14-18', 15), isTrue);
    expect(ageFits('14-18', 19), isFalse);
    expect(ageFits('16+', 17), isTrue);
    expect(ageFits('16+', 15), isFalse);
    expect(ageFits('', 15), isTrue);
  });

  test('open listings come before closed ones', () {
    expect(
      rank([
        {'title': 'closed', 'deadline': '2026-11-01'},
        {'title': 'open', 'deadline': '2026-12-20'},
      ]),
      ['open', 'closed'],
    );
  });

  test('age fit, then interests, then soonest deadline', () {
    expect(
      rank(
          [
            {'title': 'soonest', 'deadline': '2026-11-30'},
            {
              'title': 'maths',
              'deadline': '2026-12-30',
              'subjects': ['Maths'],
            },
            {
              'title': 'too old',
              'deadline': '2026-12-01',
              'age': '18+',
              'subjects': ['Maths'],
            },
          ],
          age: 15,
          interests: {'maths'}),
      ['maths', 'soonest', 'too old'],
    );
  });

  test('an empty profile falls back to soonest deadline', () {
    expect(
      rank([
        {'title': 'later', 'deadline': '2026-12-30'},
        {'title': 'no deadline'},
        {'title': 'sooner', 'deadline': '2026-12-01'},
      ]),
      ['sooner', 'later', 'no deadline'],
    );
  });
}
