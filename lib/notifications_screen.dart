import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'app_ui.dart';
import 'calendar.dart';
import 'community_feed.dart';
import 'notification_service.dart';
import 'notification_widgets.dart';

const recentNotificationLimit = 50;

/// The inbox and bell share this filter so their unread counts stay in sync.
List<QueryDocumentSnapshot<Map<String, dynamic>>> notificationsForUser(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  String uid, {
  Set<String> excludeIds = const {},
}) =>
    docs
        .where((doc) =>
            doc.data()['actorId'] != uid && !excludeIds.contains(doc.id))
        .toList();

Stream<QuerySnapshot<Map<String, dynamic>>> recentNotifications() =>
    FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(recentNotificationLimit)
        .snapshots();

Stream<QuerySnapshot<Map<String, dynamic>>> recentNotificationReads(
        String uid) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notificationReads')
        .orderBy('readAt', descending: true)
        .limit(200)
        .snapshots();

/// Used by the inbox and by notification taps handled by NotificationService.
Future<void> openAppNotification(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return;
  }
  final type = data['type']?.toString();
  final targetId = data['targetId']?.toString() ?? '';
  if (targetId.isEmpty ||
      targetId.contains('/') ||
      (type != 'post' && type != 'calendar')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This notification cannot be opened.')),
    );
    return;
  }

  final notificationId = data['notificationId']?.toString() ?? '';
  if (notificationId.isNotEmpty && !notificationId.contains('/')) {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notificationReads')
          .doc(notificationId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));
    } catch (_) {
      if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Could not mark this notification as read. You can still view the update.'),
      ));
    }
  }
  if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
    return;
  }

  if (type == 'post') {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NotificationPostScreen(postId: targetId),
    ));
    return;
  }

  try {
    final event = await FirebaseFirestore.instance
        .collection('calendarEvents')
        .doc(targetId)
        .get()
        .timeout(const Duration(seconds: 8));
    if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }
    if (!event.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This calendar event is no longer available.'),
      ));
      return;
    }
    final dateValue = event.data()?['date'];
    final date = dateValue is Timestamp
        ? dateValue.toDate()
        : DateTime.tryParse(dateValue?.toString() ?? '');
    bool isOrganizer = false;
    try {
      final user = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 4));
      isOrganizer = user.data()?['role'] == 'organizer';
    } catch (_) {
      // Opening a date does not depend on having access to organizer controls.
    }
    if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          CalendarScreen(initialDay: date, isOrganizer: isOrganizer),
    ));
  } catch (_) {
    if (!context.mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Could not open this event. Check your connection and try again.'),
    ));
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const NotificationInboxView(signedOut: true);
          }
          return _NotificationInbox(key: ValueKey(user.uid), uid: user.uid);
        },
      );
}

class _NotificationInbox extends StatefulWidget {
  final String uid;
  const _NotificationInbox({super.key, required this.uid});

  @override
  State<_NotificationInbox> createState() => _NotificationInboxState();
}

class _NotificationInboxState extends State<_NotificationInbox> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _updates;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _reads;
  bool _markingAll = false;
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _updates = recentNotifications();
    _reads = recentNotificationReads(widget.uid);
  }

  Future<void> _markAllRead(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (_markingAll || FirebaseAuth.instance.currentUser?.uid != widget.uid) {
      return;
    }
    setState(() => _markingAll = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final reads = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('notificationReads');
      for (final doc in docs) {
        batch.set(reads.doc(doc.id), {'readAt': FieldValue.serverTimestamp()});
      }
      await batch.commit().timeout(const Duration(seconds: 8));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Could not mark notifications as read. Please try again.'),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _markingAll = false);
      }
    }
  }

  Future<void> _open(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    if (_openingId != null ||
        FirebaseAuth.instance.currentUser?.uid != widget.uid) {
      return;
    }
    setState(() => _openingId = doc.id);
    try {
      await openAppNotification(
          context, {...doc.data(), 'notificationId': doc.id});
    } finally {
      if (mounted) {
        setState(() => _openingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: NotificationService.instance,
        builder: (context, _) {
          final service = NotificationService.instance;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _updates,
            builder: (context, updateSnapshot) =>
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _reads,
              builder: (context, readSnapshot) {
                final hasError =
                    updateSnapshot.hasError || readSnapshot.hasError;
                final loading =
                    !updateSnapshot.hasData || !readSnapshot.hasData;
                final docs = notificationsForUser(
                    updateSnapshot.data?.docs ?? [], widget.uid);
                final readIds =
                    readSnapshot.data?.docs.map((doc) => doc.id).toSet() ??
                        <String>{};
                final unread =
                    docs.where((doc) => !readIds.contains(doc.id)).toList();
                final items = docs.map((doc) {
                  final data = doc.data();
                  final stamp = data['createdAt'];
                  final date =
                      stamp is Timestamp ? stamp.toDate().toLocal() : null;
                  final localizations = MaterialLocalizations.of(context);
                  final timeLabel = date == null
                      ? ''
                      : '${localizations.formatMediumDate(date)} · '
                          '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
                  return NotificationItemData(
                    id: doc.id,
                    title: data['title']?.toString() ?? 'New update',
                    body: data['body']?.toString() ?? '',
                    timeLabel: timeLabel,
                    isCalendar: data['type'] == 'calendar',
                    isUnread: !readIds.contains(doc.id),
                    opening: _openingId == doc.id,
                  );
                }).toList();
                return NotificationInboxView(
                  items: items,
                  loading: loading,
                  loadError:
                      hasError ? 'Check your connection and try again.' : null,
                  onRetry: () => setState(_connect),
                  alertsEnabled: service.enabled,
                  alertsBusy: service.busy,
                  alertsError: service.error,
                  onToggleAlerts: () async {
                    if (service.enabled) {
                      await service.disable();
                    } else {
                      await service.enable();
                    }
                  },
                  markingAllRead: _markingAll,
                  onMarkAllRead: () => _markAllRead(unread),
                  onOpen: _openingId != null
                      ? null
                      : (id) => _open(docs.firstWhere((doc) => doc.id == id)),
                );
              },
            ),
          );
        },
      );
}

class NotificationPostScreen extends StatefulWidget {
  final String postId;
  const NotificationPostScreen({super.key, required this.postId});
  @override
  State<NotificationPostScreen> createState() => _NotificationPostScreenState();
}

class _NotificationPostScreenState extends State<NotificationPostScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _post;
  bool _isOrganizer = false;
  @override
  void initState() {
    super.initState();
    _connect();
    _loadRole();
  }

  void _connect() {
    _post = FirebaseFirestore.instance
        .collection('posts')
        .where(FieldPath.documentId, isEqualTo: widget.postId)
        .limit(1)
        .snapshots();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 4));
      if (mounted && FirebaseAuth.instance.currentUser?.uid == uid) {
        setState(() => _isOrganizer = doc.data()?['role'] == 'organizer');
      }
    } catch (_) {
      // The author's normal post controls remain available without this role.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(centerTitle: true, title: const AppLogo()),
        body: SafeArea(
            top: false,
            child: ContentWidth(
              maxWidth: 760,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _post,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return LoadError(
                        message: 'Could not load this post.',
                        onRetry: () => setState(_connect));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('This post is no longer available.',
                                textAlign: TextAlign.center)));
                  }
                  return ListView(padding: const EdgeInsets.all(14), children: [
                    PostCard(
                        post: snapshot.data!.docs.first,
                        isOrganizer: _isOrganizer),
                  ]);
                },
              ),
            )),
      );
}
