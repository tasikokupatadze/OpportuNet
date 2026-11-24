import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
// table_calendar's header buttons are flutter/material InkWells, which only see a
// flutter/material Material ancestor, not material_ui's.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as flutter_material
    show Material, MaterialType;

import 'app_ui.dart';

class CalendarScreen extends StatefulWidget {
  final bool isOrganizer;
  final DateTime? initialDay;
  const CalendarScreen({super.key, this.isOrganizer = false, this.initialDay});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDay;
    if (initial != null && initial.year >= 2020 && initial.year <= 2035) {
      _selectedDay = initial;
      _focusedDay = initial;
    }
    _connect();
  }

  void _connect() {
    _stream =
        FirebaseFirestore.instance.collection('calendarEvents').snapshots();
  }

  Future<void> _addEvent() async {
    final selectedDate = _selectedDay;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var category = 'Competitions';
    var saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: Text(context.l10n.addEvent),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: context.l10n.eventTitle,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? context.l10n.enterEventTitle
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.l10n.description,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: context.l10n.category),
                      items: const ['Competitions', 'Tests', 'Decisions']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_eventCategoryLabel(context, value)),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialog(() => category = value);
                              }
                            },
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text(context.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        setDialog(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await FirebaseFirestore.instance
                              .collection('calendarEvents')
                              .add({
                            'title': titleController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'category': category,
                            'date': DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                            ).toIso8601String(),
                            'createdBy': user.uid,
                          });
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                        } catch (e) {
                          debugPrint('Add calendar event: $e');
                          if (!dialogContext.mounted) return;
                          setDialog(() {
                            saving = false;
                            error =
                                context.l10n.addEventFailed;
                          });
                        }
                      },
                child: saving ? const BusyIndicator() : Text(context.l10n.add),
              ),
            ],
          ),
        ),
      ),
    );
    // Wait until the closing animation no longer builds the form fields.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    titleController.dispose();
    descriptionController.dispose();
  }

  // Event categories are stored in English; this only changes the label.
  String _eventCategoryLabel(BuildContext context, String category) =>
      switch (category) {
        'Competitions' => context.l10n.evCompetitions,
        'Tests' => context.l10n.evTests,
        'Decisions' => context.l10n.evDecisions,
        _ => category,
      };

  Color _categoryColor(String category) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (category) {
      case 'Competitions':
        return dark ? Colors.greenAccent : Colors.green.shade800;
      case 'Tests':
        return dark ? Colors.orangeAccent : Colors.brown.shade700;
      case 'Decisions':
        return dark ? Colors.purpleAccent.shade100 : Colors.purple.shade800;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
  centerTitle: true,
  title: Image.asset(
    'assets/opportunet1.png',
    height: 55,
    fit: BoxFit.contain,
    semanticLabel: 'OpportuNet',
  ),
),
        floatingActionButton: widget.isOrganizer
            ? FloatingActionButton(
                onPressed: _addEvent,
                tooltip: context.l10n.addEvent,
                child: const Icon(Icons.add),
              )
            : null,
        body: SafeArea(
          top: false,
          child: ContentWidth(
            maxWidth: 850,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  {
                    return LoadError(
                      message: context.l10n.loadCalendarFailed,
                      onRetry: () => setState(_connect),
                    );
                  }
                if (!snapshot.hasData)
                  {return const Center(child: CircularProgressIndicator());}
                final events = <DateTime, List<CalendarEvent>>{};
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data();
                  final value = data['date'];
                  final date = value is Timestamp
                      ? value.toDate()
                      : DateTime.tryParse(value?.toString() ?? '');
                  if (date == null) continue;
                  final day = DateTime.utc(date.year, date.month, date.day);
                  (events[day] ??= []).add(
                    CalendarEvent(
                      title: data['title']?.toString() ?? '',
                      description: data['description']?.toString() ?? '',
                      category: data['category']?.toString() ?? '',
                    ),
                  );
                }
                List<CalendarEvent> eventsFor(DateTime day) =>
                    events[DateTime.utc(day.year, day.month, day.day)] ?? [];
                final selectedEvents = eventsFor(_selectedDay);
                final colors = Theme.of(context).colorScheme;
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: flutter_material.Material(
                            type: flutter_material.MaterialType.transparency,
                            child: TableCalendar<CalendarEvent>(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2035, 12, 31),
                            focusedDay: _focusedDay,
                            rowHeight: 52 * textScale,
                            daysOfWeekHeight: 24 * textScale,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            eventLoader: eventsFor,
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            calendarStyle: CalendarStyle(
                              defaultTextStyle:
                                  TextStyle(color: colors.onSurface),
                              weekendTextStyle:
                                  TextStyle(color: colors.onSurface),
                              todayTextStyle: const TextStyle(color: brandInk),
                              selectedTextStyle: const TextStyle(
                                color: brandInk,
                                fontWeight: FontWeight.bold,
                              ),
                              todayDecoration: BoxDecoration(
                                color: brandBlue.withValues(alpha: 0.75),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: brandBlue,
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: BoxDecoration(
                                color: colors.error,
                                shape: BoxShape.circle,
                              ),
                              outsideDaysVisible: false,
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                color: colors.onSurfaceVariant,
                              ),
                              weekendStyle: TextStyle(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            headerStyle: const HeaderStyle(
                              titleCentered: true,
                              formatButtonVisible: false,
                            ),
                            onDaySelected: (selected, focused) => setState(() {
                              _selectedDay = selected;
                              _focusedDay = focused;
                            }),
                            onPageChanged: (focused) => _focusedDay = focused,
                          ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          context.l10n.dueOn(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(_selectedDay),
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    if (selectedEvents.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            context.l10n.noEventsToday,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverList.builder(
                          itemCount: selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = selectedEvents[index];
                            final color = _categoryColor(event.category);
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    if (event.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(event.description),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      _eventCategoryLabel(
                                        context,
                                        event.category,
                                      ),
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class CalendarEvent {
  final String title;
  final String description;
  final String category;
  CalendarEvent({
    required this.title,
    required this.description,
    required this.category,
  });
}
