import 'app_ui.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'calendar.dart';
import 'activitydetails.dart';
import 'roadmaps.dart';
import 'extracurriculars.dart';

const Map<String, (String, IconData)> kCategories = {
  "olympiads": ("Olympiads", Icons.emoji_events_rounded),
  "volunteering": ("Volunteering", Icons.volunteer_activism_rounded),
  "exchange": ("Exchange", Icons.flight_takeoff_rounded),
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
  "astronomy": Icons.public_rounded,
  "geography": Icons.map_rounded,
  "linguistics": Icons.translate_rounded,
  "english": Icons.translate_rounded,
  "economics": Icons.trending_up_rounded,
};

Stream<List<Map<String, dynamic>>> _allOpportunities() {
  final latest = <String, List<Map<String, dynamic>>>{};
  final failures = <String, Object>{};
  late final StreamController<List<Map<String, dynamic>>> ctrl;
  final subs = <StreamSubscription>[];

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
                  .map((d) => {...d.data(), kCategoryField: name})
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
      for (final s in subs) {
        s.cancel();
      }
    },
  );
  return ctrl.stream;
}

const Color _brand = Color(0xff84d6fe);
const Color _brandDark = Color(0xff2b88b4);

enum CostFilter { any, free, paid }

enum SortBy { newest, deadline, title, cheapest }

const Map<SortBy, String> kSortLabels = {
  SortBy.newest: "Newest",
  SortBy.deadline: "Deadline",
  SortBy.title: "A–Z",
  SortBy.cheapest: "Free first",
};

enum FeedLayout { grid, centered }

String _str(Map<String, dynamic> d, List<String> keys) {
  for (final k in keys) {
    final v = d[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
  }
  return "";
}

String _subject(Map<String, dynamic> d) {
  final value = _str(d, ["subject", "field"]);
  final normalized = value.toLowerCase().trim();

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
  };

  return aliases[normalized] ?? normalized;
}

String _duration(Map<String, dynamic> d) =>
    _str(d, ["duration", "length", "programDuration"]);

DateTime? _date(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

bool _isFree(String cost) {
  final c = cost.toLowerCase().trim();
  return c == '0' ||
      c == '0.0' ||
      c == '0.00' ||
      c == 'free' ||
      c == 'free of charge' ||
      c == 'no cost';
}

double _costValue(String cost) {
  if (cost.trim().isEmpty) return double.infinity;
  if (_isFree(cost)) return 0;
  final m = RegExp(r'\d+(\.\d+)?').firstMatch(cost.replaceAll(",", ""));
  return m == null ? double.infinity : double.parse(m.group(0)!);
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class HomeFeed extends StatefulWidget {
  final bool isOrganizer;
  const HomeFeed({super.key, required this.isOrganizer});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  final _searchCtrl = TextEditingController();
  String _query = "";
  late Stream<List<Map<String, dynamic>>> _stream = _allOpportunities();
  final Set<String> _categories = {};
  final Set<String> _subjects = {};
  CostFilter _cost = CostFilter.any;
  SortBy _sort = SortBy.newest;
  FeedLayout _layout = FeedLayout.grid;
  int? _myAge;

  bool _showSearch = true;

  bool get _hasFilters =>
      _categories.isNotEmpty ||
      _subjects.isNotEmpty ||
      _cost != CostFilter.any ||
      _myAge != null ||
      _sort != SortBy.newest;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _ageFits(String age, int me) {
    final nums = RegExp(r'\d+')
        .allMatches(age)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (nums.isEmpty) return true;
    if (nums.length == 1) {
      return age.contains("+") ? me >= nums[0] : me == nums[0];
    }
    return me >= nums[0] && me <= nums[1];
  }

  bool _matches(Map<String, dynamic> d) {
    final cat = (d[kCategoryField] ?? "").toString();
    final cost = (d["cost"] ?? "").toString();
    final age = (d["ageRequirements"] ?? d["age"] ?? "").toString();
    final subject = _subject(d);

    final searchableText = [
      d["title"],
      d["description"],
      d["subject"],
      d["field"],
      d["duration"],
      d["length"],
      d["programDuration"],
      d["ageRequirements"],
      d["age"],
      d["cost"],
      d["location"],
      d["country"],
      d["eligibility"],
      d["requirements"],
    ].where((v) => v != null).join(" ").toLowerCase();

    final normalizedQuery = _query.toLowerCase().trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );

    if (normalizedQuery.isNotEmpty &&
        !searchableText.contains(normalizedQuery)) {
      return false;
    }

    if (_categories.isNotEmpty && !_categories.contains(cat)) return false;

    if (_subjects.isNotEmpty && !_subjects.contains(subject)) {
      return false;
    }

    if (_cost == CostFilter.free && !_isFree(cost)) return false;
    if (_cost == CostFilter.paid && (cost.trim().isEmpty || _isFree(cost)))
      {return false;}

    if (_myAge != null && !_ageFits(age, _myAge!)) return false;

    return true;
  }

  void _sortItems(List<Map<String, dynamic>> items) {
    int newest(Map a, Map b) {
      final ta = _date(a["createdAt"]), tb = _date(b["createdAt"]);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    }

    switch (_sort) {
      case SortBy.newest:
        items.sort(newest);
      case SortBy.deadline:
        final now = DateTime.now();
        DateTime? dl(Map d) {
          final v = _date(
            d["deadline"] ?? d["registrationDeadline"] ?? d["date"],
          );
          return (v != null && v.isAfter(now)) ? v : null;
        }
        items.sort((a, b) {
          final da = dl(a), db = dl(b);
          if (da == null && db == null) return newest(a, b);
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      case SortBy.title:
        items.sort(
          (a, b) => (a["title"] ?? "").toString().toLowerCase().compareTo(
                (b["title"] ?? "").toString().toLowerCase(),
              ),
        );
      case SortBy.cheapest:
        items.sort(
          (a, b) => _costValue((a["cost"] ?? "").toString())
              .compareTo(_costValue((b["cost"] ?? "").toString())),
        );
    }
  }

  void _clearAll() => setState(() {
        _categories.clear();
        _subjects.clear();
        _cost = CostFilter.any;
        _sort = SortBy.newest;
        _myAge = null;
        _searchCtrl.clear();
        _query = "";
      });

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n.direction == ScrollDirection.reverse && _showSearch) {
      setState(() => _showSearch = false);
    } else if (n.direction == ScrollDirection.forward && !_showSearch) {
      setState(() => _showSearch = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xff1e2228) : const Color(0xfff3f6f9);

    return ContentWidth(
      child: Column(
        children: [
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.bottomCenter,
              heightFactor: _showSearch ? 1 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showSearch ? 1 : 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _topButtons(),
                    _searchRow(surface),
                    _categoryChips(),
                  ],
                ),
              ),
            ),
          ),

          // Feed
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return LoadError(
                    message:
                        "Couldn't load opportunities. Check your connection and try again.",
                    onRetry: () =>
                        setState(() => _stream = _allOpportunities()),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!.where(_matches).toList();
                _sortItems(items);

                if (items.isEmpty) return _emptyState();

                return NotificationListener<UserScrollNotification>(
                  onNotification: _onScroll,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: _feedHeader(items.length, dark),
                        ),
                      ),
                      _layout == FeedLayout.grid
                          ? _gridSliver(items)
                          : _centeredSliver(items),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _topButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  // Let labels grow with text scaling.
                  child: ElevatedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandDark,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: const BorderSide(color: _brand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CalendarScreen(isOrganizer: widget.isOrganizer),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: const Text(
                      "Academic Calendar",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  // Let labels grow with text scaling.
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandDark,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: const BorderSide(color: _brand),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoadmapScreen()),
                    ),
                    icon: const Icon(Icons.route_rounded, size: 20),
                    label: const Text(
                      "Roadmaps",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Only organizers can see this button.
          if (widget.isOrganizer) ...[
            const SizedBox(height: 10),
            SizedBox(
              // Let labels grow with text scaling.
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddActivityScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add Extracurricular",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchRow(Color surface) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Search opportunities",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _query = "";
                        }),
                      ),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Badge(
            isLabelVisible: _hasFilters,
            backgroundColor: _brandDark,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.black87,
                fixedSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              tooltip: "Filters & sort",
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(
            label: "All",
            icon: Icons.apps_rounded,
            selected: _categories.isEmpty,
            onTap: () => setState(_categories.clear),
          ),
          for (final e in kCategories.entries)
            _chip(
              label: e.value.$1,
              icon: e.value.$2,
              selected: _categories.contains(e.key),
              onTap: () => setState(() {
                _categories.contains(e.key)
                    ? _categories.remove(e.key)
                    : _categories.add(e.key);
              }),
            ),
        ],
      ),
    );
  }

  Widget _feedHeader(int count, bool dark) {
    final muted = dark ? Colors.white60 : Colors.black54;
    return Row(
      children: [
        Expanded(
          child: Text(
            "$count opportunit${count == 1 ? 'y' : 'ies'} · ${kSortLabels[_sort]}",
            style: TextStyle(fontSize: 13, color: muted),
          ),
        ),
        SegmentedButton<FeedLayout>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selectedBackgroundColor: _brand.withValues(alpha: 0.35),
          ),
          segments: const [
            ButtonSegment(
              value: FeedLayout.grid,
              icon: Icon(Icons.grid_view_rounded, size: 18),
              tooltip: "Two per row",
            ),
            ButtonSegment(
              value: FeedLayout.centered,
              icon: Icon(Icons.view_agenda_rounded, size: 18),
              tooltip: "One per row",
            ),
          ],
          selected: {_layout},
          onSelectionChanged: (s) => setState(() => _layout = s.first),
        ),
      ],
    );
  }

  // Layout 1: two activities side by side.
  Widget _gridSliver(List<Map<String, dynamic>> items) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns =
            (constraints.crossAxisExtent / (scale > 1.3 ? 300 : 245))
                .floor()
                .clamp(1, 4)
                .toInt();
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += columns) {
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: 12),
                    Expanded(
                      child: i + j < items.length
                          ? OpportunityCard(data: items[i + j], big: false)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList(delegate: SliverChildListDelegate(rows)),
        );
      },
    );
  }

  Widget _centeredSliver(List<Map<String, dynamic>> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: OpportunityCard(data: items[i], big: true),
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 18,
          color: selected ? Colors.black87 : _brandDark,
        ),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: _brand,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? Colors.black87 : null,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: selected ? _brand : Colors.black12),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 56, color: _brandDark),
            const SizedBox(height: 12),
            Text(
              _hasFilters || _query.isNotEmpty
                  ? "Nothing matches your filters"
                  : "No opportunities yet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (_hasFilters || _query.isNotEmpty)
              TextButton(onPressed: _clearAll, child: const Text("Clear all")),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(VoidCallback fn) {
            setState(fn);
            setSheet(() {});
          }

          const h = TextStyle(fontWeight: FontWeight.w700);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filters",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),

                  // Sort by
                  const Text("Sort by", style: h),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in SortBy.values)
                        ChoiceChip(
                          label: Text(kSortLabels[s]!),
                          selected: _sort == s,
                          showCheckmark: false,
                          selectedColor: _brand,
                          onSelected: (_) => update(() => _sort = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Olympiad subject
                  const Text("Olympiad subject", style: h),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in const [
                        "maths",
                        "robotics",
                        "physics",
                        "chemistry",
                        "biology",
                        "informatics",
                      ])
                        FilterChip(
                          avatar: Icon(kSubjectIcons[s], size: 16),
                          label: Text(_capitalize(s)),
                          selected: _subjects.contains(s),
                          showCheckmark: false,
                          selectedColor: _brand,
                          onSelected: (_) => update(() {
                            _subjects.contains(s)
                                ? _subjects.remove(s)
                                : _subjects.add(s);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text("Cost", style: h),
                  const SizedBox(height: 8),
                  SegmentedButton<CostFilter>(
                    segments: const [
                      ButtonSegment(value: CostFilter.any, label: Text("Any")),
                      ButtonSegment(
                        value: CostFilter.free,
                        label: Text("Free"),
                      ),
                      ButtonSegment(
                        value: CostFilter.paid,
                        label: Text("Paid"),
                      ),
                    ],
                    selected: {_cost},
                    onSelectionChanged: (s) => update(() => _cost = s.first),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Text("My age", style: h),
                      const Spacer(),
                      Text(
                        _myAge == null ? "Any age" : "$_myAge years",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text("Any age"),
                        selected: _myAge == null,
                        showCheckmark: false,
                        selectedColor: _brand,
                        onSelected: (_) => update(() => _myAge = null),
                      ),
                    ],
                  ),

                  Slider(
                    value: (_myAge ?? 12).toDouble(),
                    min: 12,
                    max: 20,
                    divisions: 8,
                    label: _myAge == null ? "Any age" : "$_myAge",
                    activeColor: _brandDark,
                    onChanged: (v) => update(() => _myAge = v.round()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          _clearAll();
                          setSheet(() {});
                        },
                        child: const Text("Reset"),
                      ),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _brandDark,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Show results"),
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

// ---------- One compact item in the feed: logo + title + key tags ----------
class OpportunityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool big; // true in the centered layout
  const OpportunityCard({super.key, required this.data, required this.big});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = (data["title"] ?? "").toString();
    final age = (data["ageRequirements"] ?? data["age"] ?? "").toString();
    final cost = (data["cost"] ?? "").toString();
    final image = (data["imageUrl"] ?? data["image"] ?? "").toString();
    final section = (data[kCategoryField] ?? "").toString();
    final cat = kCategories[section];
    final subject = _subject(data);
    final duration = _duration(data);

    // Only the most important tags (max 3).
    final tags = <(IconData, String)>[
      if (section == "olympiads" && subject.isNotEmpty)
        (
          kSubjectIcons[subject.toLowerCase()] ?? Icons.school_rounded,
          _capitalize(subject),
        ),
      if (section == "exchange" && duration.isNotEmpty)
        (Icons.schedule_rounded, duration),
      if (age.isNotEmpty) (Icons.person_outline_rounded, age),
      (
        Icons.payments_outlined,
        cost.trim().isEmpty
            ? "Cost not specified"
            : (_isFree(cost) ? "Free" : cost),
      ),
    ].take(3).toList();

    final cardColor = dark ? const Color(0xff1e2228) : Colors.white;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      // No tint: keeps the logo background from turning grey.
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityDetailsScreen(activity: data),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark ? Colors.white10 : const Color(0xffe8ecf0),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(big ? 14 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                SizedBox(
                  height: big ? 140 : 100,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _placeholder(cat?.$2),
                          )
                        : _placeholder(cat?.$2),
                  ),
                ),
                SizedBox(height: big ? 10 : 8),
                Text(
                  title,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: big ? 15 : 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: big ? 8 : 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  clipBehavior: Clip.hardEdge,
                  children: [for (final t in tags) _tag(t.$1, t.$2, big)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(IconData? icon) => Center(
        child: Icon(icon ?? Icons.star_rounded,
            size: big ? 44 : 34, color: _brand),
      );

  Widget _tag(IconData icon, String text, bool big) => Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: EdgeInsets.symmetric(horizontal: big ? 8 : 6, vertical: 3),
        decoration: BoxDecoration(
          color: _brand.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: big ? 13 : 11, color: _brandDark),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontSize: big ? 11.5 : 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}