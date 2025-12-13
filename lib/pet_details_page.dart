import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class PetDetailsPage extends StatefulWidget {
  final String petId;
  final String currentLanguage; // már nem használjuk, de ha máshol kell, maradhat

  PetDetailsPage({required this.petId, required this.currentLanguage});

  @override
  _PetDetailsPageState createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = true;
  String? _imageUrl;
  String? _breed;
  Uint8List? _imageBytes;


  final List<String> _breedList = const [
    'Beagle',
    'Boxer',
    'Bulldog',
    'Dachshund',
    'German Shepherd',
    'German Shorthaired Pointer',
    'Golden Retriever',
    'Labrador Retriever',
    'Pembroke Welsh Corgi',
    'Poodle',
    'Rottweiler',
    'Shih Tzu',
    'Siberian Husky',
  ];

  @override
  void initState() {
    super.initState();
    _loadPetDetails();
  }

  Future<void> _loadPetDetails() async {
    try {
      DocumentSnapshot petDoc =
      await _firestore.collection('pets').doc(widget.petId).get();

      if (petDoc.exists && petDoc.data() != null) {
        final petData = petDoc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = petData['name']?.toString() ?? '';
          _dobController.text = petData['dob']?.toString() ?? '';
          _weightController.text = petData['weight']?.toString() ?? '';

          _imageUrl = (petData['imageUrl'] ?? petData['profilePictureUrl'])
              ?.toString();
          _breed = petData['breed']?.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet not found')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pet details: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final result =
    await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null) return;

    try {
      final fileName =
          '${widget.petId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('pet_images/$fileName');

      final uploadTask = storageRef.putData(_imageBytes!);
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
      });

      await _firestore
          .collection('pets')
          .doc(widget.petId)
          .update({'imageUrl': downloadUrl});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  void _updatePet() async {
    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final weight = _weightController.text.trim();

    if (name.isNotEmpty &&
        dob.isNotEmpty &&
        weight.isNotEmpty &&
        _breed != null &&
        _breed!.isNotEmpty) {
      try {
        await _firestore.collection('pets').doc(widget.petId).update({
          'name': name,
          'dob': dob,
          'weight': weight,
          'breed': _breed,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet updated successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating pet: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
    }
  }

  void _deletePet() async {
    try {
      await _firestore.collection('pets').doc(widget.petId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet deleted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting pet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageUrl != null &&
                      _imageUrl!.isNotEmpty
                      ? NetworkImage(_imageUrl!)
                      : const NetworkImage(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS3hTQwsrGuYW0XGXbIB4d2noVL1ZhL7llERA&s',
                  ) as ImageProvider,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Upload Image'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration:
                const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dobController,
                decoration: const InputDecoration(
                    labelText: 'Date of Birth'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _weightController,
                decoration:
                const InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),



              DropdownButtonFormField<String>(
                decoration:
                const InputDecoration(labelText: 'Breed'),
                value: _breed != null &&
                    _breedList.contains(_breed)
                    ? _breed
                    : null,
                items: _breedList.map((breed) {
                  return DropdownMenuItem(
                    value: breed,
                    child: Text(breed),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _breed = value;
                  });
                },
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _updatePet,
                    child: const Text('Save'),
                  ),
                  ElevatedButton(
                    onPressed: _deletePet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
