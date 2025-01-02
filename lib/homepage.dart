import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:petpal/new_pet_form_page.dart';
import 'package:petpal/new_task_form_page.dart';
import 'package:petpal/pet_details_page.dart';
import 'daily_tasks_list.dart';
import 'footer.dart';
import 'chat.dart';

class HomePage extends StatefulWidget {
  final String currentLanguage;

  HomePage({required this.currentLanguage});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  Future<Map<String, String>> _getUserData() async {
    User? user = _auth.currentUser;

    if (user != null && user.email != null) {
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email!)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;
        String fullName = (userDoc['fullName'] as String?) ?? 'N/A';
        String profilePictureUrl = (userDoc['profilePictureUrl'] as String?) ?? '';

        DocumentSnapshot translationDoc = await _firestore
            .collection('translations')
            .doc(widget.currentLanguage)
            .get();

        String favoritesLabel = translationDoc.exists
            ? (translationDoc['favorites_label'] as String? ?? 'My Pets')
            : 'My Pets';

        String dailyTaskLabel = translationDoc.exists
            ? (translationDoc['daily_task'] as String? ?? 'Daily Task')
            : 'Daily Task';

        return {
          'fullName': fullName,
          'profilePictureUrl': profilePictureUrl,
          'favoritesLabel': favoritesLabel,
          'dailyTaskLabel': dailyTaskLabel
        };
      }
    }
    return {
      'fullName': 'N/A',
      'profilePictureUrl': '',
      'favoritesLabel': 'My Pets',
      'dailyTaskLabel': 'Daily Task'
    };
  }

  Future<List<Map<String, dynamic>>> _getUserPets() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot petQuery = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();

      return petQuery.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    }
    return [];
  }

  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading user data'));
          } else {
            final userData = snapshot.data ?? {
              'fullName': 'N/A',
              'profilePictureUrl': '',
              'favoritesLabel': 'My Pets',
              'dailyTaskLabel': 'Daily Task'
            };
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: userData['profilePictureUrl']!.isNotEmpty
                            ? NetworkImage(userData['profilePictureUrl']!)
                            : AssetImage('assets/placeholder.png') as ImageProvider,
                      ),
                      SizedBox(width: 16),
                      Text(
                        userData['fullName']!,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userData['favoritesLabel']!,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewPetFormPage(currentLanguage: widget.currentLanguage),
                            ),
                          );
                          _refreshData();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getUserPets(),
                    builder: (context, petSnapshot) {
                      if (petSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (petSnapshot.hasError) {
                        return Center(child: Text('Error loading pets'));
                      } else {
                        final pets = petSnapshot.data ?? [];
                        return pets.isEmpty
                            ? Text('No pets found')
                            : Container(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: pets.length,
                            itemBuilder: (context, index) {
                              final pet = pets[index];
                              final petId = pet['id'] ?? '';

                              return petId.isNotEmpty
                                  ? GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PetDetailsPage(
                                        petId: petId,
                                        currentLanguage: widget.currentLanguage,
                                      ),
                                    ),
                                  );
                                  _refreshData();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundImage: NetworkImage(
                                          pet['profilePictureUrl'] ??
                                              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS3hTQwsrGuYW0XGXbIB4d2noVL1ZhL7llERA&s',
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        pet['name'] ?? 'Unnamed',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                                  : Text('Invalid pet data');
                            },
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userData['dailyTaskLabel']!,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewTaskFormPage(),
                            ),
                          );
                          _refreshData();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: DailyTasksList(),
                  ),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: Footer(
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage()),
            );
          }
        },
        currentIndex: _selectedIndex,
      ),
    );
  }
}
