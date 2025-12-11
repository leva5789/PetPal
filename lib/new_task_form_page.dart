import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewTaskFormPage extends StatefulWidget {
  @override
  _NewTaskFormPageState createState() => _NewTaskFormPageState();
}

class _NewTaskFormPageState extends State<NewTaskFormPage> {
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedPet;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cloud Function URL a task kategorizálásához
  static const String _categorizeFunctionUrl =
      'https://categorizetask-md6ydt4via-uc.a.run.app';

  Future<List<String>> _getUserPets() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot petQuery = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();
      return petQuery.docs.map((doc) => doc['name'] as String).toList();
    }
    return [];
  }

  /// Meghívja a Cloud Functiont, ami AI-val kategorizálja a taskot
  Future<String> _categorizeTask(String description) async {
    try {
      final response = await http.post(
        Uri.parse(_categorizeFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': description}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          return category;
        }
      } else {
        print(
            'categorizeTask error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('categorizeTask exception: $e');
    }

    // Ha bármi hiba van, inkább not_understood legyen
    return 'not_understood';
  }

  void _submitTask() async {
    User? user = _auth.currentUser;
    final description = _descriptionController.text.trim();

    if (user != null &&
        _selectedDate != null &&
        _selectedPet != null &&
        description.isNotEmpty) {
      // 1) kategorizáljuk a leírást AI-jal
      final type = await _categorizeTask(description);

      // 2) mentjük a taskot Firestore-ba, a type mezővel együtt
      await _firestore.collection('tasks').add({
        'userId': user.uid,
        'description': description,
        'type': type, // ⬅️ AI által adott kategória
        'date': _selectedDate,
        'petName': _selectedPet,
        'completed': false,
      });

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${_selectedDate!.toLocal()}'.split(' ')[0],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: _getUserPets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text('Error loading pets');
                } else {
                  final petNames = snapshot.data ?? [];
                  return DropdownButton<String>(
                    value: _selectedPet,
                    hint: const Text('Select Pet'),
                    items: petNames.map((petName) {
                      return DropdownMenuItem(
                        value: petName,
                        child: Text(petName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPet = value;
                      });
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitTask,
              child: const Text('Submit Task'),
            ),
          ],
        ),
      ),
    );
  }
}
