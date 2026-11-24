import 'package:flutter_test/flutter_test.dart';
import 'package:opportunet/home_feed.dart';

void main() {
  test('every filter subject has an icon', () {
    for (final subject in kFilterSubjects) {
      expect(kSubjectIcons[subject], isNotNull, reason: subject);
    }
  });

  test('no selection matches everything', () {
    expect(matchesSubjectFilter({}, {}), isTrue);
    expect(matchesSubjectFilter({'maths'}, {}), isTrue);
  });

  test('a listed subject matches itself only', () {
    expect(matchesSubjectFilter({'maths', 'physics'}, {'physics'}), isTrue);
    expect(matchesSubjectFilter({'maths'}, {'physics'}), isFalse);
  });

  test('"other" matches unlisted subjects and the "other" tag', () {
    expect(matchesSubjectFilter({'geography'}, {'other'}), isTrue);
    expect(matchesSubjectFilter({'other'}, {'other'}), isTrue);
    expect(matchesSubjectFilter({'maths'}, {'other'}), isFalse);
    expect(matchesSubjectFilter({}, {'other'}), isFalse);
  });

  test('astronomy is read as astrophysics', () {
    expect(
        opportunitySubjects({
          'subjects': ['Astronomy']
        }),
        {'astrophysics'});
  });
}
