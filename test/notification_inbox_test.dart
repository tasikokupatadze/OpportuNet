import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportunet/notifications_screen.dart';

// No Firebase app or platform channels are initialized by these tests.
// This test-only snapshot supplies just the immutable fields the filter reads.
// ignore: subtype_of_sealed_class
class _NotificationDocument extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final String actorId;

  _NotificationDocument(this.id, this.actorId);

  @override
  Map<String, dynamic> data() => {'actorId': actorId};
}

void main() {
  final recent = [
    _NotificationDocument('new-post', 'alice'),
    _NotificationDocument('new-event', 'bob'),
    _NotificationDocument('older-post', 'carol'),
  ];

  test('inbox omits own updates and preserves latest-first order', () {
    final visible = notificationsForUser(recent, 'bob');
    expect(visible.map((doc) => doc.id), ['new-post', 'older-post']);
  });

  test('bell excludes read markers as well as own updates', () {
    final unread = notificationsForUser(recent, 'alice',
        excludeIds: {'new-event', 'notification-outside-recent-window'});
    expect(unread.map((doc) => doc.id), ['older-post']);
  });

  test('switching accounts computes an independent unread count', () {
    final aliceUnread = notificationsForUser(recent, 'alice',
        excludeIds: {'new-event', 'older-post'});
    final bobUnread = notificationsForUser(recent, 'bob');
    expect(aliceUnread, isEmpty);
    expect(bobUnread.length, 2);
    expect(recent.length, 3);
  });
}
