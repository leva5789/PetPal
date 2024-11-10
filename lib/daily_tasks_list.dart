import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyTasksList extends StatefulWidget {
  @override
  _DailyTasksListState createState() => _DailyTasksListState();
}

class _DailyTasksListState extends State<DailyTasksList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _getUserTasks() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot taskQuery = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<Map<String, dynamic>> tasks = taskQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID for easy reference
        return data;
      }).toList();

      // Filter tasks to only include those with the current date
      DateTime currentDate = DateTime.now();
      tasks.retainWhere((task) {
        DateTime taskDate = (task['date'] as Timestamp).toDate();
        return DateFormat('yyyy-MM-dd').format(taskDate) ==
            DateFormat('yyyy-MM-dd').format(currentDate);
      });

      return tasks;
    }
    return [];
  }

  void _updateTaskCompletion(String taskId, bool isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({'completed': isCompleted});
    setState(() {}); // Refresh UI after updating
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>> (
      future: _getUserTasks(),
      builder: (context, taskSnapshot) {
        if (taskSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (taskSnapshot.hasError) {
          return Center(child: Text('Error loading tasks'));
        } else {
          final tasks = taskSnapshot.data ?? [];
          int completedCount = tasks.where((task) => task['completed'] == true).length;
          int totalTasks = tasks.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: totalTasks > 0 ? completedCount / totalTasks : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('$completedCount/$totalTasks completed',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(child: Text('No tasks found'))
                    : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final date = (task['date'] as Timestamp).toDate();
                    final formattedDate =
                        '${date.month}-${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

                    return task['completed'] == true
                        ? Container() // Hide completed task
                        : Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formattedDate),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['petName'] ?? 'No Pet Name',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  task['description'] ?? 'No Description',
                                ),
                              ],
                            ),
                            Checkbox(
                              value: task['completed'] ?? false,
                              onChanged: (value) {
                                if (value != null) {
                                  _updateTaskCompletion(task['id'], value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
