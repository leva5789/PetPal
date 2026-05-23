import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'app_toast.dart';

class DailyTasksList extends StatefulWidget {
  final String? householdId;

  const DailyTasksList({Key? key, this.householdId}) : super(key: key);

  @override
  _DailyTasksListState createState() => _DailyTasksListState();
}

class _DailyTasksListState extends State<DailyTasksList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updateTaskCompletion(
      String taskId, bool isCompleted, int xpReward) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final taskRef = _firestore.collection('tasks').doc(taskId);
        final userRef = _firestore.collection('users').doc(user.uid);

        final userSnap = await transaction.get(userRef);

        transaction.update(taskRef, {
          'completed': isCompleted,
          'completedBy': isCompleted ? user.uid : FieldValue.delete(),
        });

        if (userSnap.exists) {
          final userData = userSnap.data();

          int currentXp = 0;
          if (userData is Map<String, dynamic> &&
              userData.containsKey('totalXp')) {
            currentXp = (userData['totalXp'] as num).toInt();
          }

          if (isCompleted) {
            currentXp += xpReward;
          } else {
            currentXp -= xpReward;
            if (currentXp < 0) currentXp = 0;
          }

          int newLevel = (currentXp / 1000).floor() + 1;

          transaction.update(userRef, {
            'totalXp': currentXp,
            'level': newLevel,
          });
        }
      });
    } catch (e) {
      AppToast.error(context, 'Failed to update task');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    final targetHouseholdId = widget.householdId ?? user?.uid;

    if (user == null || targetHouseholdId == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tasks')
          .where('householdId', isEqualTo: targetHouseholdId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading tasks: ${snapshot.error}'));
        } else {
          final docs = snapshot.data?.docs ?? [];
          final tasks = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return data;
          }).toList();

          DateTime currentDate = DateTime.now();
          final String todayStr = DateFormat('yyyy-MM-dd').format(currentDate);

          final todaysTasks = tasks.where((task) {
            if (task['date'] == null) return false;
            final DateTime taskDate = (task['date'] as Timestamp).toDate();
            return DateFormat('yyyy-MM-dd').format(taskDate) == todayStr;
          }).toList();

          int completedCount =
              todaysTasks.where((task) => task['completed'] == true).length;
          int totalTasks = todaysTasks.length;

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
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$completedCount/$totalTasks completed',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: todaysTasks.isEmpty
                    ? const Center(child: Text('No tasks for today'))
                    : ListView.builder(
                        itemCount: todaysTasks.length,
                        itemBuilder: (context, index) {
                          final task = todaysTasks[index];
                          final date = (task['date'] as Timestamp).toDate();
                          final formattedDate =
                              '${date.month}-${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

                          if (task['completed'] == true) {
                            return Container();
                          }

                          final int xpReward = (task['xpReward'] as int?) ?? 20;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formattedDate),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['petName'] ?? 'No Pet Name',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        task['description'] ?? 'No Description',
                                      ),
                                      Text(
                                        '+$xpReward XP',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber[700],
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Checkbox(
                                    value: task['completed'] ?? false,
                                    onChanged: (value) {
                                      if (value != null) {
                                        _updateTaskCompletion(
                                            task['id'], value, xpReward);
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
