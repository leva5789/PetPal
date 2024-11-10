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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _imageUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS3hTQwsrGuYW0XGXbIB4d2noVL1ZhL7llERA&s';

  Map<String, String>? _translations;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    DocumentSnapshot translationDoc = await _firestore
        .collection('translations')
        .doc(widget.currentLanguage)
        .get();

    setState(() {
      _translations = {
        'add_new_pet': translationDoc['add_new_pet'] ?? 'Add New Pet',
        'upload_image': translationDoc['upload_image'] ?? 'Upload Image',
        'name_label': translationDoc['name_label'] ?? 'Name',
        'dob_label': translationDoc['dob_label'] ?? 'Date of Birth',
        'weight_label': translationDoc['weight_label'] ?? 'Weight',
        'gender_label': translationDoc['gender_label'] ?? 'Gender',
        'gender_female': translationDoc['gender_female'] ?? 'Female',
        'gender_male': translationDoc['gender_male'] ?? 'Male',
        'save_pet': translationDoc['save_pet'] ?? 'Save Pet',
        'pet_added_success': translationDoc['pet_added_success'] ?? 'Pet added successfully!',
        'fill_out_all_fields': translationDoc['fill_out_all_fields'] ?? 'Please fill out all fields'
      };
    });
  }

  void _savePet() async {
    User? user = _auth.currentUser;

    if (user != null && _translations != null) {
      String userId = user.uid;
      String name = _nameController.text;
      String dob = _dobController.text;
      String weight = _weightController.text;
      String gender = _selectedGender ?? '';

      if (name.isNotEmpty && dob.isNotEmpty && weight.isNotEmpty && gender.isNotEmpty) {
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

        await newPetRef.update({'id': newPetRef.id});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translations!['pet_added_success']!)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translations!['fill_out_all_fields']!)),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
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
    if (_translations == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_translations!['add_new_pet']!),
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
                  // Placeholder for image upload functionality
                },
                child: Text(_translations!['upload_image']!),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: _translations!['name_label']),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: _translations!['dob_label'],
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
                decoration: InputDecoration(labelText: _translations!['weight_label']),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Csak számok engedélyezése
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: _translations!['gender_label']),
                value: _selectedGender,
                items: [
                  DropdownMenuItem(value: 'female', child: Text(_translations!['gender_female']!)),
                  DropdownMenuItem(value: 'male', child: Text(_translations!['gender_male']!)),
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
                child: Text(_translations!['save_pet']!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
