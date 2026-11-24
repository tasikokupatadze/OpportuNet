import 'package:flutter_test/flutter_test.dart';
import 'package:opportunet/extracurriculars.dart';

void main() {
  test('reads a fenced JSON reply and keeps valid fields', () {
    final draft = parseOpportunityDraft('''Here you go:
```json
{"title": "Tbilisi Math Camp", "description": "A week of olympiad training.",
 "category": "Olympiads", "subjects": ["maths", "Dance"],
 "website": "https://example.org/apply", "ageRequirements": "14-17",
 "cost": "Free", "deadline": "2026-12-05"}
```''')!;

    expect(draft.title, 'Tbilisi Math Camp');
    expect(draft.category, 'olympiads');
    expect(draft.subjects, {'Maths'}); // unknown subjects are dropped
    expect(draft.website, 'https://example.org/apply');
    expect(draft.deadline, DateTime(2026, 12, 5));
  });

  test('blanks out fields that do not fit their format', () {
    final draft = parseOpportunityDraft(
        '{"category": "sports", "website": "javascript:alert(1)", '
        '"deadline": "next Friday", "subjects": "Maths"}')!;

    expect(draft.category, isNull);
    expect(draft.website, '');
    expect(draft.deadline, isNull);
    expect(draft.subjects, isEmpty);
  });

  test('returns null when there is no JSON object', () {
    expect(parseOpportunityDraft('Sorry, I cannot help with that.'), isNull);
    expect(parseOpportunityDraft('{not json}'), isNull);
  });
}
