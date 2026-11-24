import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import 'activitydetails.dart';
import 'app_ui.dart';
import 'calendar.dart';
import 'extracurriculars.dart';
import 'roadmaps.dart';
import 'schools.dart';

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

const Color _brand = Color(0xff84d6fe);
const Color _brandDark = Color(0xff2b88b4);

enum CostFilter { any, free, paid }
enum SortBy { newest, deadline, title, cheapest }
enum FeedLayout { grid, centered }

const Map<SortBy, String> kSortLabels = {
  SortBy.newest: "Newest",
  SortBy.deadline: "Deadline",
  SortBy.title: "A–Z",
  SortBy.cheapest: "Free first",
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
                  .map((doc) => {...doc.data(), kCategoryField: name})
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

bool _isFree(String cost) {
  const freeValues = {
    "0", "0.0", "0.00", "free", "free of charge", "no cost",
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
  SortBy _sort = SortBy.newest;
  FeedLayout _layout = FeedLayout.grid;
  int? _myAge;

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
      return age.contains("+") ? me >= nums.first : me == nums.first;
    }
    return me >= nums[0] && me <= nums[1];
  }

  bool _matches(Map<String, dynamic> data) {
    final category = _str(data, [kCategoryField]);
    final cost = _str(data, ["cost"]);
    final age = _str(data, ["ageRequirements", "age"]);

    if (_categories.isNotEmpty && !_categories.contains(category)) {
      return false;
    }
    if (_subjects.isNotEmpty && !_subjectsOf(data).any(_subjects.contains)) {
  return false;
}
    if (_cost == CostFilter.free && !_isFree(cost)) return false;
    if (_cost == CostFilter.paid && (cost.isEmpty || _isFree(cost))) {
      return false;
    }
    if (_myAge != null && !_ageFits(age, _myAge!)) return false;

    final query = _query.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (query.isEmpty) return true;

    const fields = [
      "title", "fullTitle", "fullName", "description", "subject", "field",
      "duration", "length", "programDuration", "ageRequirements", "age",
      "cost", "location", "country", "eligibility", "requirements",
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
        final now = DateTime.now();
        DateTime? upcoming(Map<String, dynamic> data) {
          final date = _deadline(data) ?? _date(data["date"]);
          return date != null && date.isAfter(now) ? date : null;
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
      _categories.clear();
      _subjects.clear();
      _cost = CostFilter.any;
      _sort = SortBy.newest;
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
          final items = (snap.data ?? <Map<String, dynamic>>[])
              .where(_matches)
              .toList();
          _sortItems(items);

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _searchRow()),
              SliverToBoxAdapter(child: _categoryChips()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _feedHeader(
                    snap.hasData && !snap.hasError ? items.length : null,
                  ),
                ),
              ),
              if (snap.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadError(
                    message:
                        "Couldn't load opportunities. Check your connection and try again.",
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
                hintText: "Search opportunities",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: "Clear search",
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
              tooltip: "Filters and layout",
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
          chip("All", Icons.apps_rounded, _categories.isEmpty,
              () => setState(_categories.clear)),
          for (final entry in kCategories.entries)
            chip(
              entry.value.$1,
              entry.value.$2,
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
        ? "Opportunities"
        : "$count ${count == 1 ? 'opportunity' : 'opportunities'}";

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
            tooltip: "Add extracurricular",
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddActivityScreen()),
            ),
          ),
        PopupMenuButton<WidgetBuilder>(
          tooltip: "Resources",
          icon: const Icon(Icons.menu_book_outlined, size: 21),
          onSelected: (page) {
            Navigator.push(context, MaterialPageRoute(builder: page));
          },
          itemBuilder: (_) => [
            PopupMenuItem<WidgetBuilder>(
              key: const ValueKey('home-schools-shortcut'),
              value: (_) => const SchoolScreen(),
              child: const Text("Best Schools in Georgia"),
            ),
            PopupMenuItem<WidgetBuilder>(
              value: (_) => const RoadmapScreen(),
              child: const Text("Roadmaps"),
            ),
            PopupMenuItem<WidgetBuilder>(
              key: const ValueKey('home-calendar-shortcut'),
              value: (_) => CalendarScreen(isOrganizer: widget.isOrganizer),
              child: const Text("Academic Calendar"),
            ),
          ],
        ),
        PopupMenuButton<SortBy>(
          tooltip: "Sort opportunities",
          initialValue: _sort,
          onSelected: (value) => setState(() => _sort = value),
          itemBuilder: (_) => [
            for (final value in SortBy.values)
              PopupMenuItem(value: value, child: Text(kSortLabels[value]!)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(kSortLabels[_sort]!, style: const TextStyle(fontSize: 13)),
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
                        child: OpportunityCard(data: items[row], big: true),
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
              filtered ? "Nothing matches your filters" : "No opportunities yet",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (filtered)
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
                  const Text(
                    "Filters",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  const Text("Layout", style: heading),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final layout in FeedLayout.values)
                        ChoiceChip(
                          label: Text(layout == FeedLayout.grid
                              ? "Auto grid"
                              : "Single column"),
                          selected: _layout == layout,
                          onSelected: (_) => update(() => _layout = layout),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Sort by", style: heading),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final sort in SortBy.values)
                        ChoiceChip(
                          label: Text(kSortLabels[sort]!),
                          selected: _sort == sort,
                          onSelected: (_) => update(() => _sort = sort),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Olympiad subject", style: heading),
                  Wrap(
                    spacing: 8,
                    children: [
                     for (final subject in const [
  "maths", "physics", "chemistry", "biology",
  "robotics", "informatics", "programming", "astrophysics",
  "linguistics", "english", "economics", "other",
])
                        FilterChip(
                          avatar: Icon(kSubjectIcons[subject], size: 16),
                          label: Text(_capitalize(subject)),
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
                  const SizedBox(height: 16),
                  const Text("Cost", style: heading),
                  const SizedBox(height: 8),
                  SegmentedButton<CostFilter>(
                    segments: const [
                      ButtonSegment(value: CostFilter.any, label: Text("Any")),
                      ButtonSegment(value: CostFilter.free, label: Text("Free")),
                      ButtonSegment(value: CostFilter.paid, label: Text("Paid")),
                    ],
                    selected: {_cost},
                    onSelectionChanged: (values) =>
                        update(() => _cost = values.first),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("My age", style: heading),
                      const Spacer(),
                      Text(_myAge == null ? "Any age" : "$_myAge years"),
                    ],
                  ),
                  ChoiceChip(
                    label: const Text("Any age"),
                    selected: _myAge == null,
                    onSelected: (_) => update(() => _myAge = null),
                  ),
                  Slider(
                    value: (_myAge ?? 12).toDouble(),
                    min: 12,
                    max: 20,
                    divisions: 8,
                    label: _myAge?.toString() ?? "Any age",
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
                        child: const Text("Reset"),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
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

class OpportunityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool big;

  const OpportunityCard({
    super.key,
    required this.data,
    required this.big,
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

    final tags = <(IconData, String)>[
      if (section == "olympiads" && subject.isNotEmpty)
        (kSubjectIcons[subject] ?? Icons.school_outlined, _capitalize(subject)),
      if (section == "exchange" && duration.isNotEmpty)
        (Icons.schedule_rounded, duration),
      if (age.isNotEmpty) (Icons.person_outline_rounded, age),
      (
        Icons.payments_outlined,
        cost.isEmpty ? "Cost not specified" : (_isFree(cost) ? "Free" : cost),
      ),
    ];

    Widget logoFallback() => Icon(
      category?.$2 ?? Icons.school_outlined,
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
                            category.$1,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(
                          title.isEmpty ? "Untitled opportunity" : title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              if (deadline != null) ...[
                const SizedBox(height: 10),
                Text(
                  "Deadline · ${MaterialLocalizations.of(context).formatMediumDate(deadline)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
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