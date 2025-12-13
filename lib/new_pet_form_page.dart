import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class NewPetFormPage extends StatefulWidget {
  final String currentLanguage;

  NewPetFormPage({required this.currentLanguage});

  @override
  _NewPetFormPageState createState() => _NewPetFormPageState();
}

class _NewPetFormPageState extends State<NewPetFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _selectedGender;
  String? _selectedBreed;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _imageUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS3hTQwsrGuYW0XGXbIB4d2noVL1ZhL7llERA&s';

  List<String> _breedList = [
    'Beagle', 'Boxer', 'Bulldog', 'Dachshund', 'German Shepherd',
    'German Shorthaired Pointer', 'Golden Retriever', 'Labrador Retriever',
    'Pembroke Welsh Corgi', 'Poodle', 'Rottweiler', 'Shih Tzu',
    'Siberian Husky'
  ];

  @override
  void initState() {
    super.initState();
  }

  void _savePet() async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final weight = _weightController.text.trim();
    final gender = _selectedGender ?? '';
    final breed = _selectedBreed ?? '';

    if (name.isEmpty ||
        dob.isEmpty ||
        weight.isEmpty ||
        gender.isEmpty ||
        breed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    try {
      final userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      final userName =
      userDoc.exists ? (userDoc['fullName'] as String? ?? 'Unknown') : 'Unknown';

      final newPetRef = await _firestore.collection('pets').add({
        'userId': user.uid,
        'userName': userName,
        'name': name,
        'dob': dob,
        'weight': weight,
        'gender': gender,
        'breed': breed,
        'profilePictureUrl': _imageUrl,
      });

      await newPetRef.update({'id': newPetRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pet added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving pet: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
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
        child: SingleChildScrollView(
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
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Gender'),
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(
                    value: 'female',
                    child: Text('Female'),
                  ),
                  DropdownMenuItem(
                    value: 'male',
                    child: Text('Male'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              SizedBox(height: 10),
              // Kutyafajta legördülő lista
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Breed'),
                value: _selectedBreed,
                items: _breedList.map((breed) {
                  return DropdownMenuItem(
                    value: breed,
                    child: Text(breed),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBreed = value;
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
