import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../lib/notification_task_queue.dart';

void main() {
  test('timing out registration cannot let logout cleanup overtake its write',
      () async {
    final queue = NotificationTaskQueue();
    final remoteWrite = Completer<void>();
    final events = <String>[];
    final registration = queue.run(() async {
      events.add('write started');
      await remoteWrite.future;
      events.add('write committed');
    });

    await expectLater(
        registration.timeout(Duration.zero), throwsA(isA<TimeoutException>()));
    final cleanup = queue.run(() async {
      events.add('registration deleted');
    });
    await Future<void>.delayed(Duration.zero);
    expect(events, ['write started']);

    remoteWrite.complete();
    await cleanup;
    expect(
        events, ['write started', 'write committed', 'registration deleted']);
  });

  test('a failed registration does not block cleanup or the next account',
      () async {
    final queue = NotificationTaskQueue();
    final events = <String>[];
    final failedRegistration = queue.run(() async {
      events.add('registration failed');
      throw StateError('offline write rejected');
    });
    final cleanup = queue.run(() async {
      events.add('old account cleaned');
    });
    final nextAccount = queue.run(() async {
      events.add('new account registered');
    });

    await expectLater(failedRegistration, throwsStateError);
    await cleanup;
    await nextAccount;
    expect(events, [
      'registration failed',
      'old account cleaned',
      'new account registered',
    ]);
  });
}
