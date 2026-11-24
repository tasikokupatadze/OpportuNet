import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'app_ui.dart';
import 'home_feed.dart'
    show categoryLabel, kCategoryField, kCategories, opportunityTitle;
import 'saved_opportunities.dart' show kIdField;

/// Event types counted per opportunity (see the opportunityEvents rule).
enum StatEvent { view, save, share }

/// Today's date in Georgia (UTC+4 all year) as YYYY-MM-DD. The aggregator
/// in functions/ uses the same day boundary.
String tbilisiDay([DateTime? now]) {
  final t = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 4));
  return "${t.year}-${t.month.toString().padLeft(2, '0')}-"
      "${t.day.toString().padLeft(2, '0')}";
}

/// Event doc id: one per user, type, opportunity and day. The rules allow
/// create only, so a second event the same day is rejected: that is how
/// each user counts once per opportunity per day.
String statEventId(
        String uid, StatEvent type, String section, String id, String day) =>
    "${uid}_${type.name}_${section}_${id}_$day";

final Set<String> _loggedThisSession = {};

/// Records that the signed-in user viewed, saved or shared [data].
/// Fire-and-forget: stats must never get in the way of the app.
void logOpportunityEvent(Map<String, dynamic> data, StatEvent type) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final section = data[kCategoryField]?.toString() ?? "";
  final id = data[kIdField]?.toString() ?? "";
  if (uid == null ||
      !kCategories.containsKey(section) ||
      id.isEmpty ||
      id.contains('/')) {
    return;
  }

  final day = tbilisiDay();
  final docId = statEventId(uid, type, section, id, day);
  if (!_loggedThisSession.add(docId)) return;

  FirebaseFirestore.instance.collection('opportunityEvents').doc(docId).set({
    'uid': uid,
    'type': type.name,
    'section': section,
    'opportunityId': id,
    'day': day,
    'createdAt': FieldValue.serverTimestamp(),
  }).catchError((_) {
    // Already counted today (the rules refuse a second create) or offline.
  });
}

/// Totals per event type over the days in [days] on or after [fromDay].
Map<String, int> sumStatDays(Map<String, dynamic>? days, String fromDay) {
  final totals = {for (final t in StatEvent.values) t.name: 0};
  days?.forEach((day, counts) {
    if (day.compareTo(fromDay) < 0 || counts is! Map) return;
    for (final t in StatEvent.values) {
      final n = counts[t.name];
      if (n is num) totals[t.name] = totals[t.name]! + n.toInt();
    }
  });
  return totals;
}

/// Organizer-only: views, saves and shares per opportunity, updated daily.
class OpportunityStatsScreen extends StatefulWidget {
  const OpportunityStatsScreen({super.key});

  @override
  State<OpportunityStatsScreen> createState() => _OpportunityStatsScreenState();
}

class _OpportunityStatsScreenState extends State<OpportunityStatsScreen> {
  int _range = 7;
  late Future<_StatsData> _data = _load();

  Future<_StatsData> _load() async {
    final db = FirebaseFirestore.instance;
    final stats = await db.collection('opportunityStats').get();
    final titles = <String, String>{};
    // Titles come from the listings themselves; deleted ones keep their id.
    await Future.wait([
      for (final section in kCategories.keys)
        db.collection(section).get().then((snap) {
          for (final doc in snap.docs) {
            titles["${section}_${doc.id}"] = opportunityTitle(doc.data());
          }
        }),
    ]);
    return _StatsData(stats.docs, titles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.usageStats)),
      body: ContentWidth(
        child: FutureBuilder<_StatsData>(
          future: _data,
          builder: (context, snap) {
            if (snap.hasError) {
              return LoadError(
                message: context.l10n.loadStatsFailed,
                onRetry: () => setState(() => _data = _load()),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final fromDay = tbilisiDay(
                DateTime.now().subtract(Duration(days: _range - 1)));
            final rows = [
              for (final doc in snap.data!.docs)
                (
                  doc: doc,
                  totals: sumStatDays(
                      doc.data()['days'] as Map<String, dynamic>?, fromDay),
                ),
            ]..sort((a, b) =>
                (b.totals['view']! + b.totals['save']! + b.totals['share']!)
                    .compareTo(a.totals['view']! +
                        a.totals['save']! +
                        a.totals['share']!));
            final all = {for (final t in StatEvent.values) t.name: 0};
            for (final row in rows) {
              row.totals.forEach((k, v) => all[k] = all[k]! + v);
            }

            Widget total(String label, int n, IconData icon) => Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Icon(icon, color: brandBlueDark),
                          Text("$n",
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          Text(label, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 7, label: Text(context.l10n.last7Days)),
                    ButtonSegment(
                        value: 30, label: Text(context.l10n.last30Days)),
                  ],
                  selected: {_range},
                  onSelectionChanged: (s) => setState(() => _range = s.first),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  total(context.l10n.statViews, all['view']!,
                      Icons.visibility_rounded),
                  total(context.l10n.statSaves, all['save']!,
                      Icons.bookmark_rounded),
                  total(context.l10n.statShares, all['share']!,
                      Icons.share_rounded),
                ]),
                const SizedBox(height: 16),
                Text(context.l10n.topOpportunities,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (rows.every((r) => r.totals.values.every((n) => n == 0)))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(context.l10n.noStatsYet,
                        textAlign: TextAlign.center),
                  ),
                for (final row in rows.take(20))
                  if (row.totals.values.any((n) => n > 0))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        snap.data!.titles[row.doc.id] ??
                            "${row.doc.data()['opportunityId'] ?? row.doc.id}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(categoryLabel(
                          context, "${row.doc.data()['section'] ?? ''}")),
                      trailing: Text(
                        "👁 ${row.totals['view']}  🔖 ${row.totals['save']}  "
                        "↗ ${row.totals['share']}",
                      ),
                    ),
                const SizedBox(height: 8),
                Text(context.l10n.statsUpdatedDaily,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsData {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Map<String, String> titles;
  const _StatsData(this.docs, this.titles);
}
