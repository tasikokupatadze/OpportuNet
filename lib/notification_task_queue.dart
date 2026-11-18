/// Serializes device registration and cleanup, including pending offline writes.
/// Apply caller timeouts to the returned future, never inside the queued task:
/// timing out a caller must not allow cleanup to overtake an unfinished write.
class NotificationTaskQueue {
  Future<void> _tail = Future<void>.value();

  Future<void> run(Future<void> Function() task) {
    final result = _tail.then((_) => task());
    // A failed registration must not prevent the following cleanup from running.
    _tail =
        result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }
}
