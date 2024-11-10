import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewPetFormPage extends StatefulWidget {
  final String currentLanguage; // Ha szükséges, továbbítsd a nyelvi kódot

  NewPetFormPage({required this.currentLanguage});

  @override
  _NewPetFormPageState createState() => _NewPetFormPageState();
}

class _NewPetFormPageState extends State<NewPetFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _selectedGender;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _imageUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS3hTQwsrGuYW0XGXbIB4d2noVL1ZhL7llERA&s';

  void _savePet() async {
    User? user = _auth.currentUser;

    if (user != null) {
      String userId = user.uid;
      String name = _nameController.text;
      String dob = _dobController.text;
      String weight = _weightController.text;
      String gender = _selectedGender ?? '';

      if (name.isNotEmpty && dob.isNotEmpty && weight.isNotEmpty && gender.isNotEmpty) {
        // Get the full name of the user
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        String userName = userDoc.exists ? (userDoc['fullName'] as String? ?? 'Unknown') : 'Unknown';

        DocumentReference newPetRef = await _firestore.collection('pets').add({
          'userId': userId,
          'userName': userName,
          'name': name,
          'dob': dob,
          'weight': weight,
          'gender': gender,
          'profilePictureUrl': _imageUrl,
        });

        // Add the document ID to the pet document
        await newPetRef.update({'id': newPetRef.id});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pet added successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill out all fields')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Hozzáadva, hogy elkerüljük a túlfedést
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(_imageUrl),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Placeholder for image upload functionality
                },
                child: Text('Upload Image'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _dobController,
                decoration: InputDecoration(labelText: 'Date of Birth'),
                keyboardType: TextInputType.datetime,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Gender'),
                items: [
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePet,
                child: Text('Save Pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
