import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:procastimate_app/models/task.dart';
import 'package:procastimate_app/models/task_data.dart'; 
import 'main_screen.dart';
import 'score_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 0;

  List<Task> _getTasksForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final tasks = tasksByDate[key] ?? [];
    return tasks.where((t) => !t.completed).toList();
  }

  void _onItemTapped(int i) {
    setState(() => _selectedIndex = i);
    if (i == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else if (i == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScoreScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _selectedDay != null ? _getTasksForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF), // soft beige background
      appBar: AppBar(
        backgroundColor: Colors.brown.shade800,
        title: const Text("Calendar", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar<Task>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getTasksForDay,
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.black87),
              weekendTextStyle: TextStyle(color: Colors.brown.shade600),
              todayDecoration: BoxDecoration(
                color: Colors.orange.shade300,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.brown.shade400,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red.shade300,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.brown.shade800, fontSize: 18),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.brown.shade700),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.brown.shade700),
            ),
          ),

          Expanded(
            child: selectedTasks.isEmpty
                ? const Center(
                    child: Text(
                      "No tasks for this day ✨",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(task.description ?? ""),
                          trailing: Text(
                            task.dueDate != null ? DateFormat('MM/dd HH:mm').format(task.dueDate!) : "",
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Score'),
        ],
        selectedItemColor: Colors.brown.shade800,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
