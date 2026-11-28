import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'activitydetails.dart';
import 'app_ui.dart';
import 'extracurriculars.dart';
import 'opportunity_stats.dart';
import 'pending_opportunities.dart';
import 'roadmaps.dart';
import 'saved_opportunities.dart';
import 'schools.dart';

const Map<String, IconData> kCategories = {
  "olympiads": Icons.emoji_events_rounded,
  "volunteering": Icons.volunteer_activism_rounded,
  "exchange": Icons.flight_takeoff_rounded,
};

String categoryLabel(BuildContext context, String key) => switch (key) {
      "olympiads" => context.l10n.catOlympiads,
      "volunteering" => context.l10n.catVolunteering,
      "exchange" => context.l10n.catExchange,
      _ => key,
    };

String subjectLabel(BuildContext context, String key) => switch (key) {
      "maths" => context.l10n.subjectMaths,
      "physics" => context.l10n.subjectPhysics,
      "chemistry" => context.l10n.subjectChemistry,
      "biology" => context.l10n.subjectBiology,
      "robotics" => context.l10n.subjectRobotics,
      "informatics" => context.l10n.subjectInformatics,
      "programming" => context.l10n.subjectProgramming,
      "astrophysics" => context.l10n.subjectAstrophysics,
      "linguistics" => context.l10n.subjectLinguistics,
      "english" => context.l10n.subjectEnglish,
      "economics" => context.l10n.subjectEconomics,
      "other" => context.l10n.subjectOther,
      _ => _capitalize(key),
    };

const String kCategoryField = "_section";

const Map<String, IconData> kSubjectIcons = {
  "maths": Icons.calculate_rounded,
  "math": Icons.calculate_rounded,
  "mathematics": Icons.calculate_rounded,
  "robotics": Icons.precision_manufacturing_rounded,
  "physics": Icons.bolt_rounded,
  "chemistry": Icons.science_rounded,
  "biology": Icons.biotech_rounded,
  "informatics": Icons.computer_rounded,
  "programming": Icons.code_rounded,
  "astrophysics": Icons.public_rounded,
  "astronomy": Icons.public_rounded,
  "geography": Icons.map_rounded,
  "linguistics": Icons.translate_rounded,
  "english": Icons.translate_rounded,
  "economics": Icons.trending_up_rounded,
  "other": Icons.more_horiz_rounded,
};

/// Subject keys offered in the Home filter sheet (kActivitySubjects,
/// lowercased).
const List<String> kFilterSubjects = [
  "maths",
  "physics",
  "chemistry",
  "biology",
  "robotics",
  "informatics",
  "programming",
  "astrophysics",
  "linguistics",
  "english",
  "economics",
  "other",
];

/// Whether a listing with [subjects] passes the subject filter [selected].
/// "other" matches any subject outside [kFilterSubjects] (e.g. geography)
/// as well as listings tagged "other" itself.
bool matchesSubjectFilter(Set<String> subjects, Set<String> selected) {
  if (selected.isEmpty) return true;
  if (subjects.any(selected.contains)) return true;
  return selected.contains("other") &&
      subjects.any((s) => !kFilterSubjects.contains(s));
}

const Color _brand = brandBlue;
const Color _brandDark = brandBlueDark;

enum CostFilter { any, free, paid }

enum SortBy { forYou, newest, deadline, title, cheapest }

enum FeedLayout { grid, centered }

String sortLabel(BuildContext context, SortBy sort) => switch (sort) {
      SortBy.forYou => context.l10n.sortForYou,
      SortBy.newest => context.l10n.sortNewest,
      SortBy.deadline => context.l10n.sortDeadline,
      SortBy.title => context.l10n.sortTitle,
      SortBy.cheapest => context.l10n.sortFreeFirst,
    };

Stream<List<Map<String, dynamic>>> _allOpportunities() {
  final latest = <String, List<Map<String, dynamic>>>{};
  final failures = <String, Object>{};
  final subs = <StreamSubscription>[];
  late final StreamController<List<Map<String, dynamic>>> ctrl;

  void emit() {
    if (failures.isNotEmpty) {
      ctrl.addError(failures.values.first);
    } else if (latest.length == kCategories.length) {
      ctrl.add(latest.values.expand((list) => list).toList());
    }
  }

  ctrl = StreamController(
    onListen: () {
      for (final name in kCategories.keys) {
        subs.add(
          FirebaseFirestore.instance.collection(name).snapshots().listen(
            (snap) {
              failures.remove(name);
              latest[name] = snap.docs
                  .map((doc) =>
                      {...doc.data(), kCategoryField: name, kIdField: doc.id})
                  .toList();
              emit();
            },
            onError: (Object error, StackTrace stack) {
              failures[name] = error;
              emit();
            },
          ),
        );
      }
    },
    onCancel: () {
      for (final sub in subs) {
        sub.cancel();
      }
    },
  );

  return ctrl.stream;
}

String _str(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return "";
}

String _title(Map<String, dynamic> data) =>
    _str(data, ["fullTitle", "fullName", "title"]);

Set<String> _subjectsOf(Map<String, dynamic> data) {
  const aliases = {
    "math": "maths",
    "mathematics": "maths",
    "math olympiad": "maths",
    "physics olympiad": "physics",
    "chemistry olympiad": "chemistry",
    "biology olympiad": "biology",
    "computer science": "informatics",
    "informatics olympiad": "informatics",
    "robotics olympiad": "robotics",
    "astronomy": "astrophysics",
  };

  final subjects = <String>{};

  for (final field in ["subjects", "subject", "field"]) {
    final value = data[field];
    final entries = value is List ? value : [value];

    for (final entry in entries.whereType<String>()) {
      for (final part in entry.split(',')) {
        final name = part.trim().toLowerCase();
        if (name.isNotEmpty) subjects.add(aliases[name] ?? name);
      }
    }
  }

  return subjects;
}

// The existing card uses the first subject for its tag.
String _subject(Map<String, dynamic> data) {
  final subjects = _subjectsOf(data);
  return subjects.isEmpty ? "" : subjects.first;
}

String _duration(Map<String, dynamic> data) =>
    _str(data, ["duration", "length", "programDuration"]);

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value.trim());
  return null;
}

DateTime? _deadline(Map<String, dynamic> data) =>
    _date(data["deadline"]) ?? _date(data["registrationDeadline"]);

/// Whether a student aged [me] fits an age requirement such as "14-18",
/// "16+" or "15". Unknown requirements fit everyone.
bool ageFits(String age, int me) {
  final nums = RegExp(r'\d+')
      .allMatches(age)
      .map((m) => int.parse(m.group(0)!))
      .toList();

  if (nums.isEmpty) return true;
  if (nums.length == 1) {
    return age.contains("+") ? me >= nums.first : me == nums.first;
  }
  return me >= nums[0] && me <= nums[1];
}

/// "For you" order: open listings first, then those whose age requirement
/// fits [age], then those sharing more subjects with [interests], then the
/// soonest deadline. Listings with no deadline count as open but come after
/// dated ones.
int compareForYou(
  Map<String, dynamic> a,
  Map<String, dynamic> b, {
  int? age,
  Set<String> interests = const {},
  DateTime? now,
}) {
  DateTime? deadlineOf(Map<String, dynamic> data) =>
      _deadline(data) ?? _date(data["date"]);
  bool isOpen(Map<String, dynamic> data) {
    final date = deadlineOf(data);
    return date == null || daysUntil(date, now: now) >= 0;
  }

  int fits(Map<String, dynamic> data) =>
      age != null && ageFits(_str(data, ["ageRequirements", "age"]), age)
          ? 1
          : 0;
  int overlap(Map<String, dynamic> data) =>
      _subjectsOf(data).where(interests.contains).length;

  var result = (isOpen(b) ? 1 : 0) - (isOpen(a) ? 1 : 0);
  if (result != 0) return result;
  result = fits(b) - fits(a);
  if (result != 0) return result;
  result = overlap(b) - overlap(a);
  if (result != 0) return result;

  final da = deadlineOf(a);
  final db = deadlineOf(b);
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
}

/// Title, deadline and subjects exactly as the Home feed reads them.
/// Ask AI uses these to describe listings to the assistant.
String opportunityTitle(Map<String, dynamic> data) => _title(data);
DateTime? opportunityDeadline(Map<String, dynamic> data) => _deadline(data);
Set<String> opportunitySubjects(Map<String, dynamic> data) => _subjectsOf(data);

bool _isFree(String cost) {
  const freeValues = {
    "0",
    "0.0",
    "0.00",
    "free",
    "free of charge",
    "no cost",
  };
  return freeValues.contains(cost.toLowerCase().trim());
}

double _costValue(String cost) {
  if (cost.trim().isEmpty) return double.infinity;
  if (_isFree(cost)) return 0;

  final match = RegExp(r'\d+(\.\d+)?').firstMatch(cost.replaceAll(",", ""));
  return match == null ? double.infinity : double.parse(match.group(0)!);
}

class HomeFeed extends StatefulWidget {
  final bool isOrganizer;

  const HomeFeed({super.key, required this.isOrganizer});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  final _searchCtrl = TextEditingController();
  final Set<String> _categories = {};
  final Set<String> _subjects = {};

  late Stream<List<Map<String, dynamic>>> _stream = _allOpportunities();

  String _query = "";
  CostFilter _cost = CostFilter.any;
  SortBy _sort = SortBy.deadline;
  FeedLayout _layout = FeedLayout.grid;
  int? _myAge;
  bool _savedOnly = false;
  Set<String> _saved = {};
  StreamSubscription<Set<String>>? _savedSub;
  // From users/{uid}, for the "For you" order.
  int? _profileAge;
  Set<String> _interests = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  @override
  void initState() {
    super.initState();
    _savedSub = savedOpportunityKeys().listen((keys) {
      if (mounted) setState(() => _saved = keys);
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        final data = doc.data() ?? const <String, dynamic>{};
        final age = int.tryParse('${data['age'] ?? ''}'.trim());
        final interests = data['interests'];
        if (!mounted) return;
        setState(() {
          _profileAge = age != null && age > 5 && age < 100 ? age : null;
          _interests = interests is List
              ? interests.whereType<String>().toSet()
              : <String>{};
        });
      }, onError: (_) {});
    }
  }

  bool _isSaved(Map<String, dynamic> data) =>
      _saved.contains(opportunityKey(data));

  VoidCallback? _toggleFor(Map<String, dynamic> data) =>
      opportunityKey(data) == null
          ? null
          : () => toggleSaved(context, data, save: !_isSaved(data));

  /// Subjects are olympiad subjects: the filter is shown and applied only
  /// while Olympiads are in view (no category chosen, or Olympiads chosen).
  bool get _subjectFilterApplies =>
      _categories.isEmpty || _categories.contains("olympiads");

  bool get _hasFilters =>
      _savedOnly ||
      _categories.isNotEmpty ||
      (_subjectFilterApplies && _subjects.isNotEmpty) ||
      _cost != CostFilter.any ||
      _myAge != null ||
      _sort != SortBy.deadline;

  @override
  void dispose() {
    _savedSub?.cancel();
    _profileSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(Map<String, dynamic> data) {
    final category = _str(data, [kCategoryField]);
    final cost = _str(data, ["cost"]);
    final age = _str(data, ["ageRequirements", "age"]);

    if (_savedOnly && !_isSaved(data)) return false;
    if (_categories.isNotEmpty && !_categories.contains(category)) {
      return false;
    }
    if (_subjectFilterApplies &&
        !matchesSubjectFilter(_subjectsOf(data), _subjects)) {
      return false;
    }
    if (_cost == CostFilter.free && !_isFree(cost)) return false;
    if (_cost == CostFilter.paid && (cost.isEmpty || _isFree(cost))) {
      return false;
    }
    if (_myAge != null && !ageFits(age, _myAge!)) return false;

    final query = _query.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (query.isEmpty) return true;

    const fields = [
      "title",
      "fullTitle",
      "fullName",
      "description",
      "subject",
      "field",
      "duration",
      "length",
      "programDuration",
      "ageRequirements",
      "age",
      "cost",
      "location",
      "country",
      "eligibility",
      "requirements",
    ];

    final searchable = fields
        .map((field) => data[field])
        .where((value) => value != null)
        .join(" ")
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');

    return searchable.contains(query);
  }

  void _sortItems(List<Map<String, dynamic>> items) {
    int newest(Map<String, dynamic> a, Map<String, dynamic> b) {
      final ta = _date(a["createdAt"]);
      final tb = _date(b["createdAt"]);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    }

    switch (_sort) {
      case SortBy.forYou:
        items.sort((a, b) =>
            compareForYou(a, b, age: _profileAge, interests: _interests));
        break;

      case SortBy.newest:
        items.sort(newest);
        break;

      case SortBy.title:
        items.sort((a, b) =>
            _title(a).toLowerCase().compareTo(_title(b).toLowerCase()));
        break;

      case SortBy.cheapest:
        items.sort((a, b) => _costValue(_str(a, ["cost"]))
            .compareTo(_costValue(_str(b, ["cost"]))));
        break;

      case SortBy.deadline:
        DateTime? upcoming(Map<String, dynamic> data) {
          final date = _deadline(data) ?? _date(data["date"]);
          return date != null && daysUntil(date) >= 0 ? date : null;
        }

        items.sort((a, b) {
          final da = upcoming(a);
          final db = upcoming(b);
          if (da == null && db == null) return newest(a, b);
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        break;
    }
  }

  void _clearAll() {
    setState(() {
      _savedOnly = false;
      _categories.clear();
      _subjects.clear();
      _cost = CostFilter.any;
      _sort = SortBy.deadline;
      _myAge = null;
      _query = "";
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          final items =
              (snap.data ?? <Map<String, dynamic>>[]).where(_matches).toList();
          _sortItems(items);

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _searchRow()),
              SliverToBoxAdapter(child: _shortcuts()),
              SliverToBoxAdapter(child: _categoryChips()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _feedHeader(
                    snap.hasData && !snap.hasError ? items.length : null,
                  ),
                ),
              ),
              if (_sort == SortBy.forYou &&
                  _profileAge == null &&
                  _interests.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.auto_awesome_rounded,
                            color: _brandDark),
                        title: Text(context.l10n.forYouEmptyProfile),
                      ),
                    ),
                  ),
                ),
              if (snap.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadError(
                    message: context.l10n.loadOpportunitiesFailed,
                    onRetry: () =>
                        setState(() => _stream = _allOpportunities()),
                  ),
                )
              else if (!snap.hasData)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(),
                )
              else
                _opportunitiesSliver(items),
            ],
          );
        },
      ),
    );
  }

  Widget _searchRow() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) => setState(() => _query = value.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchOpportunities,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.l10n.clearSearch,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _query = "";
                        }),
                      ),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: _hasFilters,
            backgroundColor: _brandDark,
            child: IconButton.filled(
              tooltip: context.l10n.filtersAndLayout,
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.tune_rounded),
              style: IconButton.styleFrom(
                fixedSize: const Size(48, 48),
                backgroundColor: _brand,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcuts() {
    final colors = Theme.of(context).colorScheme;

    Widget tile(Key key, String label, IconData icon, WidgetBuilder page) {
      return Expanded(
        child: Material(
          key: key,
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: page)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: _brandDark),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Row(
        children: [
          tile(const ValueKey('home-roadmaps-shortcut'), context.l10n.roadmaps,
              Icons.route_rounded, (_) => const RoadmapScreen()),
          const SizedBox(width: 8),
          tile(
              const ValueKey('home-schools-shortcut'),
              context.l10n.schoolsInGeorgia,
              Icons.school_rounded,
              (_) => const SchoolScreen()),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final height = 48.0 + (scale > 1 ? (scale - 1) * 20 : 0);

    Widget chip(String label, IconData icon, bool selected, VoidCallback tap) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Center(
          child: FilterChip(
            avatar: Icon(
              icon,
              size: 16,
              color: selected ? Colors.black87 : _brandDark,
            ),
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            selectedColor: _brand,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black87 : null,
            ),
            shape: const StadiumBorder(),
            onSelected: (_) => tap(),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(context.l10n.all, Icons.apps_rounded, _categories.isEmpty,
              () => setState(_categories.clear)),
          chip(
            _saved.isEmpty
                ? context.l10n.saved
                : "${context.l10n.saved} (${_saved.length})",
            Icons.bookmark_rounded,
            _savedOnly,
            () => setState(() => _savedOnly = !_savedOnly),
          ),
          for (final entry in kCategories.entries)
            chip(
              categoryLabel(context, entry.key),
              entry.value,
              _categories.contains(entry.key),
              () => setState(() {
                if (!_categories.remove(entry.key)) {
                  _categories.add(entry.key);
                }
              }),
            ),
        ],
      ),
    );
  }

  Widget _feedHeader(int? count) {
    final colors = Theme.of(context).colorScheme;
    final countText = count == null
        ? context.l10n.opportunities
        : context.l10n.opportunityCount(count);

    return Row(
      children: [
        Expanded(
          child: Text(
            countText,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ),
        if (widget.isOrganizer)
          IconButton(
            tooltip: context.l10n.reviewQueue,
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PendingOpportunitiesScreen()),
            ),
          ),
        if (widget.isOrganizer)
          IconButton(
            tooltip: context.l10n.usageStats,
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OpportunityStatsScreen()),
            ),
          ),
        if (widget.isOrganizer)
          IconButton(
            tooltip: context.l10n.addOpportunity,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddActivityScreen()),
            ),
          ),
        PopupMenuButton<SortBy>(
          tooltip: context.l10n.sortOpportunities,
          initialValue: _sort,
          onSelected: (value) => setState(() => _sort = value),
          itemBuilder: (_) => [
            for (final value in SortBy.values)
              PopupMenuItem(
                  value: value, child: Text(sortLabel(context, value))),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sortLabel(context, _sort),
                    style: const TextStyle(fontSize: 13)),
                const Icon(Icons.expand_more, size: 17),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _opportunitiesSliver(List<Map<String, dynamic>> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final singleColumn = _layout == FeedLayout.centered;
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final columnWidth = scale > 1.3 ? 340 : 280;
          final columns = singleColumn
              ? 1
              : (constraints.crossAxisExtent / columnWidth)
                  .floor()
                  .clamp(1, 4)
                  .toInt();
          final rowCount = (items.length + columns - 1) ~/ columns;

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, row) {
                if (singleColumn) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: OpportunityCard(
                          data: items[row],
                          big: true,
                          saved: _isSaved(items[row]),
                          onToggleSave: _toggleFor(items[row]),
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int col = 0; col < columns; col++) ...[
                        if (col > 0) const SizedBox(width: 12),
                        Expanded(
                          child: row * columns + col < items.length
                              ? OpportunityCard(
                                  data: items[row * columns + col],
                                  big: false,
                                  saved: _isSaved(items[row * columns + col]),
                                  onToggleSave:
                                      _toggleFor(items[row * columns + col]),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              },
              childCount: rowCount,
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    final filtered = _hasFilters || _query.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: _brandDark),
            const SizedBox(height: 10),
            Text(
              filtered
                  ? context.l10n.nothingMatches
                  : context.l10n.noOpportunitiesYet,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (filtered)
              TextButton(
                  onPressed: _clearAll, child: Text(context.l10n.clearAll)),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          void update(VoidCallback change) {
            setState(change);
            setSheet(() {});
          }

          const heading = TextStyle(fontWeight: FontWeight.w700);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.filters,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  Text(context.l10n.layout, style: heading),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final layout in FeedLayout.values)
                        ChoiceChip(
                          label: Text(layout == FeedLayout.grid
                              ? context.l10n.autoGrid
                              : context.l10n.singleColumn),
                          selected: _layout == layout,
                          onSelected: (_) => update(() => _layout = layout),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(context.l10n.sortBy, style: heading),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final sort in SortBy.values)
                        ChoiceChip(
                          label: Text(sortLabel(context, sort)),
                          selected: _sort == sort,
                          onSelected: (_) => update(() => _sort = sort),
                        ),
                    ],
                  ),
                  if (_subjectFilterApplies) ...[
                    const SizedBox(height: 16),
                    Text(context.l10n.olympiadSubject, style: heading),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final subject in kFilterSubjects)
                          FilterChip(
                            avatar: Icon(kSubjectIcons[subject], size: 16),
                            label: Text(subjectLabel(context, subject)),
                            selected: _subjects.contains(subject),
                            onSelected: (selected) => update(() {
                              if (selected) {
                                _subjects.add(subject);
                              } else {
                                _subjects.remove(subject);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(context.l10n.cost, style: heading),
                  const SizedBox(height: 8),
                  SegmentedButton<CostFilter>(
                    segments: [
                      ButtonSegment(
                          value: CostFilter.any,
                          label: Text(context.l10n.costAny)),
                      ButtonSegment(
                          value: CostFilter.free,
                          label: Text(context.l10n.free)),
                      ButtonSegment(
                          value: CostFilter.paid,
                          label: Text(context.l10n.paid)),
                    ],
                    selected: {_cost},
                    onSelectionChanged: (values) =>
                        update(() => _cost = values.first),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(context.l10n.myAge, style: heading),
                      const Spacer(),
                      Text(_myAge == null
                          ? context.l10n.anyAge
                          : context.l10n.yearsOld(_myAge!)),
                    ],
                  ),
                  ChoiceChip(
                    label: Text(context.l10n.anyAge),
                    selected: _myAge == null,
                    onSelected: (_) => update(() => _myAge = null),
                  ),
                  Slider(
                    value: (_myAge ?? 12).toDouble(),
                    min: 12,
                    max: 20,
                    divisions: 8,
                    label: _myAge?.toString() ?? context.l10n.anyAge,
                    onChanged: (value) => update(() => _myAge = value.round()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          _clearAll();
                          setSheet(() {});
                        },
                        child: Text(context.l10n.reset),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(context.l10n.showResults),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OpportunityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool big;
  final bool saved;
  final VoidCallback? onToggleSave;

  const OpportunityCard({
    super.key,
    required this.data,
    required this.big,
    this.saved = false,
    this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final category = kCategories[_str(data, [kCategoryField])];
    final title = _title(data);
    final image = _str(data, ["imageUrl", "image"]);
    final age = _str(data, ["ageRequirements", "age"]);
    final cost = _str(data, ["cost"]);
    final subject = _subject(data);
    final duration = _duration(data);
    final section = _str(data, [kCategoryField]);
    final deadline = _deadline(data);
    final closed = deadline != null && daysUntil(deadline) < 0;

    final tags = <(IconData, String)>[
      if (section == "olympiads" && subject.isNotEmpty)
        (
          kSubjectIcons[subject] ?? Icons.school_outlined,
          subjectLabel(context, subject),
        ),
      if (section == "exchange" && duration.isNotEmpty)
        (Icons.schedule_rounded, duration),
      if (age.isNotEmpty) (Icons.person_outline_rounded, age),
      (
        Icons.payments_outlined,
        cost.isEmpty
            ? context.l10n.costNotSpecified
            : (_isFree(cost) ? context.l10n.free : cost),
      ),
    ];

    Widget logoFallback() => Icon(
          category ?? Icons.school_outlined,
          size: 25,
          color: _brandDark,
        );

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityDetailsScreen(activity: data),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(big ? 16 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: image.isEmpty
                        ? logoFallback()
                        : Image.network(
                            image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => logoFallback(),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category != null)
                          Text(
                            categoryLabel(context, section),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(
                          title.isEmpty
                              ? context.l10n.untitledOpportunity
                              : title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: closed
                                ? colors.onSurfaceVariant
                                : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (onToggleSave == null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    )
                  else
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: saved
                          ? context.l10n.unsaveOpportunity
                          : context.l10n.saveOpportunity,
                      onPressed: onToggleSave,
                      icon: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: saved ? _brandDark : colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (deadline != null) ...[
                const SizedBox(height: 10),
                _DeadlineLabel(deadline: deadline),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _brand.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tag.$1, size: 13, color: _brandDark),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              tag.$2,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Whole calendar days until [deadline]; negative once it has passed.
int daysUntil(DateTime deadline, {DateTime? now}) {
  now ??= DateTime.now();
  // UTC dates so a daylight-saving change can't make a day 23 hours long.
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(deadline.year, deadline.month, deadline.day);
  return day.difference(today).inDays;
}

class _DeadlineLabel extends StatelessWidget {
  final DateTime deadline;
  const _DeadlineLabel({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final days = daysUntil(deadline);
    final date = MaterialLocalizations.of(context).formatMediumDate(deadline);

    final (String text, Color bg, Color fg) = switch (days) {
      < 0 => (
          context.l10n.deadlineClosed(date),
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant
        ),
      0 => (
          context.l10n.closesToday,
          colors.errorContainer,
          colors.onErrorContainer
        ),
      1 => (
          context.l10n.closesTomorrow,
          colors.errorContainer,
          colors.onErrorContainer
        ),
      <= 14 => (
          context.l10n.closesInDays(days, date),
          colors.errorContainer,
          colors.onErrorContainer
        ),
      _ => (
          context.l10n.deadlineOn(date),
          Colors.transparent,
          colors.onSurface
        ),
    };

    return Container(
      padding: bg == Colors.transparent
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
