import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'app_ui.dart';
import 'home_feed.dart' show kCategoryField;

/// Added to each opportunity map by the Home feed: its Firestore document id.
const String kIdField = "_id";

CollectionReference<Map<String, dynamic>>? _savedCollection() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('savedOpportunities');
}

/// "olympiads/abc123", or null when the map has no section or id.
String? opportunityKey(Map<String, dynamic> data) {
  final section = data[kCategoryField]?.toString() ?? '';
  final id = data[kIdField]?.toString() ?? '';
  if (section.isEmpty || id.isEmpty || id.contains('/')) return null;
  return '$section/$id';
}

/// Live set of the signed-in user's saved opportunity keys.
Stream<Set<String>> savedOpportunityKeys() {
  final saved = _savedCollection();
  if (saved == null) return Stream.value(<String>{});
  return saved.snapshots().map((snap) => {
        for (final doc in snap.docs)
          if (doc.data()['key'] is String) doc.data()['key'] as String,
      });
}

/// Saves or unsaves [data] and tells the user what happened.
/// The daily reminder job reads these documents (notification-functions).
Future<void> toggleSaved(
  BuildContext context,
  Map<String, dynamic> data, {
  required bool save,
}) async {
  final saved = _savedCollection();
  final key = opportunityKey(data);
  if (saved == null || key == null) return;

  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  // Reminders are sent in the language the app was in when saving.
  final lang = Localizations.localeOf(context).languageCode == 'ka' ? 'ka' : 'en';
  final hasDeadline =
      data['deadline'] != null || data['registrationDeadline'] != null;
  final doc = saved.doc(key.replaceAll('/', '_'));

  try {
    if (save) {
      await doc.set({
        'key': key,
        'section': data[kCategoryField],
        'opportunityId': data[kIdField],
        'lang': lang,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.delete();
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(!save
          ? l10n.removedFromSavedOpportunities
          : hasDeadline
              ? l10n.savedWithReminder
              : l10n.savedConfirm),
    ));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
  }
}

/// Bookmark button for screens that show a single opportunity.
class SaveOpportunityButton extends StatefulWidget {
  final Map<String, dynamic> data;
  const SaveOpportunityButton({super.key, required this.data});

  @override
  State<SaveOpportunityButton> createState() => _SaveOpportunityButtonState();
}

class _SaveOpportunityButtonState extends State<SaveOpportunityButton> {
  late final Stream<Set<String>> _keys = savedOpportunityKeys();

  @override
  Widget build(BuildContext context) {
    final key = opportunityKey(widget.data);
    if (key == null) return const SizedBox.shrink();

    return StreamBuilder<Set<String>>(
      stream: _keys,
      builder: (context, snapshot) {
        final saved = snapshot.data?.contains(key) ?? false;
        return IconButton(
          tooltip: saved
              ? context.l10n.unsaveOpportunity
              : context.l10n.saveOpportunity,
          icon: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: brandBlueDark,
          ),
          onPressed: snapshot.hasData
              ? () => toggleSaved(context, widget.data, save: !saved)
              : null,
        );
      },
    );
  }
}
