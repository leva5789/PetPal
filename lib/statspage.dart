import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'footer.dart';
import 'weightstats.dart';

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _getUserPetsWithStats() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot petQuery = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<Map<String, dynamic>> pets = petQuery.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      for (var pet in pets) {
        // Validate and process pet data
        final petName = pet['name'] ?? 'Unnamed';
        final petWeight = double.tryParse(pet['weight']?.toString() ?? '0') ?? 0.0;
        final petPicture = pet['profilePictureUrl'] ?? 'https://via.placeholder.com/150';

        pet['name'] = petName;
        pet['weight'] = petWeight;
        pet['profilePictureUrl'] = petPicture;

        // Fetch tasks for the pet
        QuerySnapshot taskQuery = await _firestore
            .collection('tasks')
            .where('userId', isEqualTo: user.uid)
            .where('petName', isEqualTo: petName)
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
            .get();

        final tasks = taskQuery.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        final completedTasks = tasks.where((task) => task['completed'] == true).length;
        final totalTasks = tasks.length;

        pet['completionRate'] = totalTasks > 0
            ? ((completedTasks / totalTasks) * 100).round()
            : 0;
      }

      return pets;
    }
    return [];
  }

  void _refreshPage() {
    setState(() {}); // Triggers a rebuild and reloads the FutureBuilder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Your Pets'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getUserPetsWithStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading pets: ${snapshot.error}'));
          } else {
            final pets = snapshot.data ?? [];
            return pets.isEmpty
                ? Center(child: Text('No pets found'))
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(
                          pet['profilePictureUrl'],
                        ),
                      ),
                      title: Text(
                        pet['name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weight: ${pet['weight']} kg'),
                          Text('Tasks Completed: ${pet['completionRate']}%'),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WeightStatsPage(
                              petId: pet['id'],
                              petName: pet['name'],
                            ),
                          ),
                        );
                        _refreshPage();
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
      bottomNavigationBar: Footer(
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.pop(context); // Navigate back to HomePage
          }
        },
        currentIndex: 2,
      ),
    );
  }
}
