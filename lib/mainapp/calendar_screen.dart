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

  // ✅ Only return incomplete tasks
  List<Task> _getTasksForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final tasks = tasksByDate[key] ?? [];
    return tasks.where((t) => !t.completed).toList();
  }

  void _onItemTapped(int i) {
    setState(() => _selectedIndex = i);
    if (i == 0) {
      // stay
    } else if (i == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else if (i == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScoreScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _selectedDay != null ? _getTasksForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Calendar", style: TextStyle(color: Colors.brown)),
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
            // ✅ Only incomplete tasks generate markers
            eventLoader: _getTasksForDay,
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.black),
              weekendTextStyle: TextStyle(color: Colors.black87),
              todayDecoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: selectedTasks.length,
              itemBuilder: (context, index) {
                final task = selectedTasks[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
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
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black45,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
