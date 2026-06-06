import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  final bool isOrganizer;

  const CalendarScreen({
    super.key,
    this.isOrganizer = false,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEventsFromFirestore();
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalized = DateTime.utc(day.year, day.month, day.day);
    return _events[normalized] ?? [];
  }

  Future<void> _loadEventsFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('calendarEvents').get();

      final Map<DateTime, List<CalendarEvent>> loadedEvents = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final String title = data['title'] ?? '';
        final String description = data['description'] ?? '';
        final String category = data['category'] ?? '';
        final String dateString = data['date'] ?? '';

        if (dateString.isEmpty) continue;

        final parsedDate = DateTime.parse(dateString);
        final normalizedDate = DateTime.utc(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );

        if (loadedEvents[normalizedDate] == null) {
          loadedEvents[normalizedDate] = [];
        }

        loadedEvents[normalizedDate]!.add(
          CalendarEvent(
            title: title,
            description: description,
            category: category,
          ),
        );
      }

      setState(() {
        _events.clear();
        _events.addAll(loadedEvents);
      });
    } catch (e) {}
  }

  void _addEvent() {
    final titlectrl = TextEditingController();
    final descctrl = TextEditingController();
    String selectedCategory = "Competitions";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text("Add Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titlectrl,
                      decoration: InputDecoration(
                        labelText: "Event Title",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descctrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Competitions",
                          child: Text("Competitions"),
                        ),
                        DropdownMenuItem(
                          value: "Tests",
                          child: Text("Tests"),
                        ),
                        DropdownMenuItem(
                          value: "Decisions",
                          child: Text("Decisions"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff84d6fe),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final title = titlectrl.text.trim();
                    final description = descctrl.text.trim();

                    if (title.isEmpty) return;

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    try {
                      await FirebaseFirestore.instance
                          .collection('calendarEvents')
                          .add({
                        'title': title,
                        'description': description,
                        'category': selectedCategory,
                        'date': DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day,
                        ).toIso8601String(),
                        'createdBy': user.uid,
                      });

                      await _loadEventsFromFirestore();

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Event added")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to add event")),
                      );
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case "Competitions":
        return Colors.green;
      case "Tests":
        return Colors.orange;
      case "Decisions":
        return Colors.purple.shade900;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xfff7fbff),
      appBar: AppBar(
        title: Image.asset(
          'assets/opportunet1.png',
          height: 60,
        ),
        centerTitle: true,
      ),
      floatingActionButton: widget.isOrganizer
          ? FloatingActionButton(
              backgroundColor: const Color(0xff84d6fe),
              onPressed: _addEvent,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xff84d6fe),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Due on ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Expanded(
            child: selectedEvents.isEmpty
                ? const Center(
                    child: Text(
                      "No events for this day",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      final color = _categoryColor(event.category);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 10,
                              height: 60,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    event.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      event.category,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
