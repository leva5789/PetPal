import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<List<String>> _getUserPets() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot petQuery = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();
      return petQuery.docs
          .map((doc) => doc['name'] as String)
          .toList();
    }
    return [];
  }

  void _submitTask() async {
    User? user = _auth.currentUser;
    if (user != null && _selectedDate != null && _selectedPet != null) {
      await _firestore.collection('tasks').add({
        'userId': user.uid,
        'description': _descriptionController.text,
        'date': _selectedDate,
        'petName': _selectedPet,
        'completed': false,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
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
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: _getUserPets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error loading pets');
                } else {
                  final petNames = snapshot.data ?? [];
                  return DropdownButton<String>(
                    value: _selectedPet,
                    hint: Text('Select Pet'),
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
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitTask,
              child: Text('Submit Task'),
            ),
          ],
        ),
      ),
    );
  }
}