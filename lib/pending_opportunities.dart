import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_ui.dart';
import 'extracurriculars.dart' show kActivitySubjects;
import 'home_feed.dart' show categoryLabel, kCategories, subjectLabel;

CollectionReference<Map<String, dynamic>> get _pending =>
    FirebaseFirestore.instance.collection('pendingOpportunities');
CollectionReference<Map<String, dynamic>> get _sources =>
    FirebaseFirestore.instance.collection('opportunitySources');

/// Fields an organizer may edit before approving (see the rules).
const kPendingEditableFields = [
  'title',
  'description',
  'website',
  'ageRequirements',
  'cost',
  'category',
  'subjects',
  'deadline',
];

/// The listing a pending draft publishes as: the same fields
/// AddActivityScreen writes, plus where it came from. Null when the draft
/// has no title or no valid category.
Map<String, dynamic>? listingFromDraft(
    Map<String, dynamic> draft, String organizerUid) {
  final title = (draft['title'] ?? '').toString().trim();
  final category = (draft['category'] ?? '').toString();
  if (title.isEmpty || !kCategories.containsKey(category)) return null;
  final subjects = [
    for (final s in (draft['subjects'] as List? ?? const []))
      if (kActivitySubjects.contains(s)) s as String,
  ];
  return {
    'title': title,
    'description': (draft['description'] ?? '').toString().trim(),
    'website': (draft['website'] ?? '').toString().trim(),
    'subjects': subjects,
    if (subjects.isNotEmpty) 'subject': subjects.first,
    'ageRequirements': (draft['ageRequirements'] ?? '').toString().trim(),
    'cost': (draft['cost'] ?? '').toString().trim(),
    if (draft['deadline'] is Timestamp) 'deadline': draft['deadline'],
    'sourceUrl': draft['sourceUrl'] ?? '',
    'createdBy': organizerUid,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// Organizer review queue for drafts the daily collectOpportunities job
/// found. Nothing is published until an organizer approves it.
class PendingOpportunitiesScreen extends StatelessWidget {
  const PendingOpportunitiesScreen({super.key});

  Future<void> _approve(BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final listing = uid == null ? null : listingFromDraft(doc.data(), uid);
    if (listing == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.needTitleCategory)));
      return;
    }
    final db = FirebaseFirestore.instance;
    final published = db.collection(doc.data()['category'] as String).doc();
    final batch = db.batch()
      ..set(published, listing)
      ..update(doc.reference, {
        'status': 'approved',
        'publishedId': published.id,
        'reviewedBy': uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    try {
      await batch.commit();
      messenger.showSnackBar(SnackBar(content: Text(l10n.activityPublished)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reviewFailed)));
    }
  }

  Future<void> _reject(BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      // Kept (not deleted) so the collector never drafts this URL again.
      await doc.reference.update({
        'status': 'rejected',
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reviewFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.reviewQueue),
        actions: [
          IconButton(
            tooltip: context.l10n.opportunitySources,
            icon: const Icon(Icons.rss_feed_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const OpportunitySourcesScreen()),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _pending.where('status', isEqualTo: 'pending').snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text(context.l10n.checkConnection));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs.toList()
              ..sort((a, b) {
                final ta = a.data()['createdAt'];
                final tb = b.data()['createdAt'];
                if (ta is! Timestamp || tb is! Timestamp) return 0;
                return tb.compareTo(ta);
              });
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(context.l10n.noPendingOpportunities,
                      textAlign: TextAlign.center),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, i) => _PendingCard(
                doc: docs[i],
                onApprove: () => _approve(context, docs[i]),
                onReject: () => _reject(context, docs[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onApprove, onReject;

  const _PendingCard(
      {required this.doc, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final category = (d['category'] ?? '').toString();
    final deadline = d['deadline'];
    final localizations = MaterialLocalizations.of(context);
    final facts = [
      if (category.isNotEmpty) categoryLabel(context, category),
      if (deadline is Timestamp)
        context.l10n
            .deadlineOn(localizations.formatMediumDate(deadline.toDate())),
      if ('${d['ageRequirements'] ?? ''}'.isNotEmpty) '${d['ageRequirements']}',
      if ('${d['cost'] ?? ''}'.isNotEmpty) '${d['cost']}',
    ];
    final sourceUrl = '${d['sourceUrl'] ?? ''}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${d['title'] ?? ''}'.isEmpty
                  ? '${d['sourceTitle'] ?? ''}'
                  : '${d['title']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (facts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(facts.join(' · '),
                    style: const TextStyle(color: brandBlueDark)),
              ),
            if ('${d['description'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${d['description']}',
                    maxLines: 5, overflow: TextOverflow.ellipsis),
              ),
            if (sourceUrl.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => launchUrl(Uri.parse(sourceUrl),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(
                  context.l10n.fromSource('${d['sourceName'] ?? ''}'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                    onPressed: onReject, child: Text(context.l10n.reject)),
                OutlinedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => _EditDraftSheet(doc: doc),
                  ),
                  child: Text(context.l10n.edit),
                ),
                FilledButton(
                    onPressed: onApprove, child: Text(context.l10n.approve)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDraftSheet extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _EditDraftSheet({required this.doc});

  @override
  State<_EditDraftSheet> createState() => _EditDraftSheetState();
}

class _EditDraftSheetState extends State<_EditDraftSheet> {
  late final Map<String, dynamic> _d = widget.doc.data();
  late final _title = TextEditingController(text: '${_d['title'] ?? ''}');
  late final _description =
      TextEditingController(text: '${_d['description'] ?? ''}');
  late final _website = TextEditingController(text: '${_d['website'] ?? ''}');
  late final _age =
      TextEditingController(text: '${_d['ageRequirements'] ?? ''}');
  late final _cost = TextEditingController(text: '${_d['cost'] ?? ''}');
  late String? _category =
      kCategories.containsKey(_d['category']) ? _d['category'] : null;
  late final Set<String> _subjects = {
    for (final s in (_d['subjects'] as List? ?? const []))
      if (kActivitySubjects.contains(s)) s as String,
  };
  late DateTime? _deadline = _d['deadline'] is Timestamp
      ? (_d['deadline'] as Timestamp).toDate()
      : null;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _description, _website, _age, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    try {
      await widget.doc.reference.update({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'website': _website.text.trim(),
        'ageRequirements': _age.text.trim(),
        'cost': _cost.text.trim(),
        'category': _category ?? '',
        'subjects': [
          for (final s in kActivitySubjects)
            if (_subjects.contains(s)) s,
        ],
        'deadline': _deadline == null
            ? null
            : Timestamp.fromDate(DateTime.utc(
                _deadline!.year, _deadline!.month, _deadline!.day)),
      });
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reviewFailed)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label, {int maxLines = 1}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            maxLines: maxLines,
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder()),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            field(_title, context.l10n.titleField),
            field(_description, context.l10n.description, maxLines: 5),
            field(_website, context.l10n.website),
            field(_age, context.l10n.ageRequirements),
            field(_cost, context.l10n.cost),
            Text(context.l10n.category,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Wrap(
              spacing: 8,
              children: [
                for (final c in kCategories.keys)
                  ChoiceChip(
                    label: Text(categoryLabel(context, c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.l10n.subjects,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Wrap(
              spacing: 8,
              children: [
                for (final s in kActivitySubjects)
                  FilterChip(
                    label: Text(subjectLabel(context, s.toLowerCase())),
                    selected: _subjects.contains(s),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _subjects.add(s);
                      } else {
                        _subjects.remove(s);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: Text(_deadline == null
                  ? context.l10n.deadlineOptional
                  : MaterialLocalizations.of(context)
                      .formatMediumDate(_deadline!)),
              trailing: _deadline == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _deadline = null),
                    ),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 3),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: _saving ? const BusyIndicator() : Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Organizer-managed RSS / WordPress feeds the daily job reads.
class OpportunitySourcesScreen extends StatelessWidget {
  const OpportunitySourcesScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    final url = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.addSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: InputDecoration(labelText: context.l10n.name)),
            TextField(
              controller: url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: context.l10n.feedUrl,
                hintText: 'https://example.org/feed',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.add)),
        ],
      ),
    );
    final feed = url.text.trim();
    final title = name.text.trim();
    name.dispose();
    url.dispose();
    if (ok != true || !context.mounted) return;

    final uri = Uri.tryParse(feed);
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.scheme == 'https' || uri.scheme == 'http') ||
        feed.length > 500) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.invalidFeedUrl)));
      return;
    }
    await _sources.add({
      'name': title.isEmpty ? uri.host : title,
      'feedUrl': feed,
      'enabled': true,
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.opportunitySources)),
      floatingActionButton: FloatingActionButton(
        tooltip: context.l10n.addSource,
        onPressed: () => _add(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: ContentWidth(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _sources.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text(context.l10n.checkConnection));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(context.l10n.sourcesHelp),
                const SizedBox(height: 8),
                for (final doc in docs)
                  Card(
                    child: SwitchListTile(
                      value: doc.data()['enabled'] == true,
                      onChanged: (on) => doc.reference.update({'enabled': on}),
                      title: Text('${doc.data()['name'] ?? ''}'),
                      subtitle: Text([
                        '${doc.data()['feedUrl'] ?? ''}',
                        if ('${doc.data()['lastError'] ?? ''}'.isNotEmpty)
                          context.l10n
                              .sourceError('${doc.data()['lastError']}'),
                      ].join('\n')),
                      secondary: IconButton(
                        tooltip: context.l10n.delete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => doc.reference.delete(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
