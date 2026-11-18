import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'app_ui.dart';
import 'notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, snapshot) {
          final uid = snapshot.data?.uid;
          if (uid == null) {
            return const SizedBox.shrink();
          }
          return _UnreadBell(key: ValueKey(uid), uid: uid);
        },
      );
}

class _UnreadBell extends StatefulWidget {
  final String uid;
  const _UnreadBell({super.key, required this.uid});
  @override
  State<_UnreadBell> createState() => _UnreadBellState();
}

class _UnreadBellState extends State<_UnreadBell> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _updates;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _reads;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _updates = recentNotifications();
    _reads = recentNotificationReads(widget.uid);
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _updates,
        builder: (context, updates) =>
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _reads,
          builder: (context, reads) {
            final failed = updates.hasError || reads.hasError;
            final readIds =
                reads.data?.docs.map((doc) => doc.id).toSet() ?? <String>{};
            final count = updates.hasData && reads.hasData
                ? notificationsForUser(updates.data!.docs, widget.uid,
                        excludeIds: readIds)
                    .length
                : 0;
            final label = failed
                ? 'Could not load notifications. Open to retry.'
                : count == 0
                    ? 'Notifications'
                    : 'Notifications: $count unread recent updates';
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: label,
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: brandBlue.withValues(alpha: 0.18),
                  foregroundColor: theme.brightness == Brightness.dark
                      ? brandBlue
                      : const Color(0xff17658b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ));
                  if (mounted &&
                      FirebaseAuth.instance.currentUser?.uid == widget.uid) {
                    setState(_connect);
                  }
                },
                icon: Badge(
                  isLabelVisible: failed || count > 0,
                  backgroundColor: failed ? theme.colorScheme.error : brandInk,
                  textColor: failed ? theme.colorScheme.onError : Colors.white,
                  label: Text(failed ? '!' : '$count'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
            );
          },
        ),
      );
}
