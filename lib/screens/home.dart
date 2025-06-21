import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcourse/models/exercise_models.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<DateTime, List<Exercise>> _exercises = {};
  double _totalDistanceToday = 0.0;
  double _averageSpeedToday = 0.0;
  Duration _totalDurationToday = Duration.zero;

  double _calendarFontSize = 17.0; // Default font size
  FontWeight _calendarFontWeight = FontWeight.w600; // Default font weight

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchExercises();
    _calculateDailySummary(_selectedDay!);
  }

  Future<void> _fetchExercises() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('exercises')
        .orderBy('start_time', descending: false)
        .get();

    final Map<DateTime, List<Exercise>> newExercises = {};
    for (var doc in snapshot.docs) {
      final exercise = Exercise.fromMap(doc.data());
      final date = DateTime(
          exercise.statuses.first.time.year,
          exercise.statuses.first.time.month,
          exercise.statuses.first.time.day);
      if (newExercises[date] == null) {
        newExercises[date] = [];
      }
      newExercises[date]!.add(exercise);
    }

    setState(() {
      _exercises = newExercises;
    });
  }

  void _calculateDailySummary(DateTime day) {
    final exercisesToday = _getExercisesForDay(day);
    double totalDistance = 0.0;
    double totalSpeed = 0.0;
    Duration totalDuration = Duration.zero;
    int exerciseCount = 0;

    for (var exercise in exercisesToday) {
      totalDistance += exercise.distance;
      totalSpeed += exercise.avgSpeed;
      if (exercise.statuses.isNotEmpty) {
        final startTime = exercise.statuses.first.time;
        final endTime = exercise.statuses.last.time;
        totalDuration += endTime.difference(startTime);
      }
      exerciseCount++;
    }

    setState(() {
      _totalDistanceToday = totalDistance;
      _averageSpeedToday = exerciseCount > 0 ? totalSpeed / exerciseCount : 0.0;
      _totalDurationToday = totalDuration;
    });
  }

  List<Exercise> _getExercisesForDay(DateTime day) {
    return _exercises[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to see your calendar.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'My Activities',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 38),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _calculateDailySummary(selectedDay);
              },
              onFormatChanged: (format) {
                // Do nothing to disable format changes
              },
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              daysOfWeekStyle: DaysOfWeekStyle(
                // decoration: BoxDecoration(
                //   border: Border(
                //     bottom: BorderSide(
                //       color: Colors.grey.shade700, // Added a subtle bottom border for visual separation
                //       width: 30.0,
                //     ),
                //   ),
                // ),
                weekdayStyle: TextStyle(color: Colors.white, fontSize: 10, fontWeight: _calendarFontWeight),
                weekendStyle: TextStyle(color: Colors.white, fontSize: 10, fontWeight: _calendarFontWeight),
                dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date)[0],
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final hasExercises = _getExercisesForDay(day).isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.all(2.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasExercises ? Colors.orange : Colors.white,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: hasExercises ? Colors.white : Colors.black,
                        fontSize: _calendarFontSize,
                        fontWeight: _calendarFontWeight,
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final hasExercises = _getExercisesForDay(day).isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.all(2.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade300, width: 2.0), // Orange border for today
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: _calendarFontSize,
                        fontWeight: _calendarFontWeight,
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  final hasExercises = _getExercisesForDay(day).isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.all(2.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasExercises ? Colors.orange.shade900 : Colors.grey,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8.0),
                      border: isSameDay(day, DateTime.now())
                          ? Border.all(color: Colors.orange.shade300, width: 2.0)
                          : null,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _calendarFontSize,
                        fontWeight: _calendarFontWeight,
                      ),
                    ),
                  );
                },
                outsideBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(2.0),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: _calendarFontSize, // Slightly larger font size
                        fontWeight: _calendarFontWeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity, // Set width to fill the whole width
            margin: const EdgeInsets.symmetric(horizontal: 28.0), // Re-add horizontal margin for spacing
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure children stretch vertically
                    children: [
                      Container(
                        width: 60.0, // Set a constant width for the container
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '${DateFormat('dd').format(_selectedDay!)}', // Display only the day
                          textAlign: TextAlign.center, // Center the text horizontally
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Stack(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 0.0),
                                          child: Text(
                                            '${(_totalDistanceToday / 1000).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 42, fontFamily: 'PlusJakartaSans', color: Colors.black, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 0.0),
                                          child: Text(
                                            'km',
                                            style: const TextStyle(fontSize: 18, fontFamily: 'PlusJakartaSans', color: Colors.black, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 0,
                                  child: Text(
                                    'distance',
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Stack(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 0.0),
                                          child: Text(
                                            '${_totalDurationToday.inHours.toString().padLeft(2, '0')}',
                                            style: const TextStyle(fontSize: 42, fontFamily: 'PlusJakartaSans', color: Colors.black, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 0.0),
                                          child: Text(
                                            'h',
                                            style: const TextStyle(fontSize: 18, fontFamily: 'PlusJakartaSans', color: Colors.black, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 0.0),
                                          child: Text(
                                            '${_totalDurationToday.inMinutes.remainder(60).toString().padLeft(2, '0')}',
                                            style: const TextStyle(fontSize: 42, fontFamily: 'PlusJakartaSans', color: Colors.black, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 0.0),
                                          child: Text(
                                            'min',
                                            style: const TextStyle(fontSize: 18, fontFamily: 'PlusJakartaSans', color: Colors.black, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 0,
                                  child: Text(
                                    'duration',
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: Stack(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 0.0),
                                          child: Text(
                                            '${(_averageSpeedToday * 3.6).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 42, fontFamily: 'PlusJakartaSans', color: Colors.black, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 0.0),
                                          child: Text(
                                            'km/h',
                                            style: const TextStyle(fontSize: 18, fontFamily: 'PlusJakartaSans', color: Colors.black, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 0,
                                  child: Text(
                                    'speed',
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
