import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportunet/pending_opportunities.dart';

void main() {
  test('approving needs a title and a known category', () {
    expect(
        listingFromDraft({'title': '', 'category': 'olympiads'}, 'u'), isNull);
    expect(listingFromDraft({'title': 'A', 'category': 'posts'}, 'u'), isNull);
  });

  test('publishes the same fields as the add screen, plus sourceUrl', () {
    final deadline = Timestamp.fromDate(DateTime.utc(2027, 3, 1));
    final listing = listingFromDraft({
      'title': ' Math Olympiad ',
      'category': 'olympiads',
      'subjects': ['Maths', 'Cooking'],
      'deadline': deadline,
      'sourceUrl': 'https://example.org/a',
      'status': 'pending',
    }, 'organizer1')!;
    expect(listing['title'], 'Math Olympiad');
    expect(listing['subjects'], ['Maths']);
    expect(listing['subject'], 'Maths');
    expect(listing['deadline'], deadline);
    expect(listing['sourceUrl'], 'https://example.org/a');
    expect(listing['createdBy'], 'organizer1');
    expect(listing.containsKey('status'), isFalse);
  });
}
