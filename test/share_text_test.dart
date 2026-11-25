import 'package:flutter_test/flutter_test.dart';
import 'package:opportunet/activitydetails.dart';

void main() {
  test('share text has title, website and the app line', () {
    expect(opportunityShareText(' Math Olympiad ', 'https://a.org', 'App'),
        'Math Olympiad\nhttps://a.org\nApp');
  });

  test('share text skips an empty website', () {
    expect(opportunityShareText('Camp', ' ', 'App'), 'Camp\nApp');
  });
}
