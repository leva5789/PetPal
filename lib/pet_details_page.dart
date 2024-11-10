import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class PetDetailsPage extends StatefulWidget {
  final String petId;
  final String currentLanguage; // Nyelvi kód

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
  Uint8List? _imageBytes;
  Map<String, String>? _translations;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _loadPetDetails();
  }

  Future<void> _loadTranslations() async {
    DocumentSnapshot translationDoc = await _firestore
        .collection('translations')
        .doc(widget.currentLanguage)
        .get();

    setState(() {
      _translations = {
        'pet_details_title': translationDoc['pet_details_title'] ?? 'Pet Details',
        'upload_image_button': translationDoc['upload_image_button'] ?? 'Upload Image',
        'name_label': translationDoc['name_label'] ?? 'Name',
        'dob_label': translationDoc['dob_label'] ?? 'Date of Birth',
        'weight_label': translationDoc['weight_label'] ?? 'Weight',
        'save_button': translationDoc['save_button'] ?? 'Save',
        'delete_button': translationDoc['delete_button'] ?? 'Delete',
        'pet_not_found': translationDoc['pet_not_found'] ?? 'Pet not found',
        'error_loading_pet_details': translationDoc['error_loading_pet_details'] ?? 'Error loading pet details: ',
        'image_uploaded_success': translationDoc['image_uploaded_success'] ?? 'Image uploaded successfully!',
        'error_uploading_image': translationDoc['error_uploading_image'] ?? 'Error uploading image: ',
        'pet_updated_success': translationDoc['pet_updated_success'] ?? 'Pet updated successfully!',
        'error_updating_pet': translationDoc['error_updating_pet'] ?? 'Error updating pet: ',
        'fill_out_all_fields': translationDoc['fill_out_all_fields'] ?? 'Please fill out all fields',
        'pet_deleted_success': translationDoc['pet_deleted_success'] ?? 'Pet deleted successfully!',
        'error_deleting_pet': translationDoc['error_deleting_pet'] ?? 'Error deleting pet: '
      };
    });
  }

  Future<void> _loadPetDetails() async {
    try {
      DocumentSnapshot petDoc = await _firestore.collection('pets').doc(widget.petId).get();
      if (petDoc.exists && petDoc.data() != null) {
        Map<String, dynamic>? petData = petDoc.data() as Map<String, dynamic>?;
        setState(() {
          _nameController.text = petData?['name']?.toString() ?? '';
          _dobController.text = petData?['dob']?.toString() ?? '';
          _weightController.text = petData?['weight']?.toString() ?? '';
          _imageUrl = petData?['imageUrl']?.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translations?['pet_not_found'] ?? 'Pet not found')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translations?['error_loading_pet_details'] ?? 'Error loading pet details:'} $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

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
      String fileName = '${widget.petId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child('pet_images/$fileName');

      UploadTask uploadTask = storageRef.putData(_imageBytes!);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
      });

      await _firestore.collection('pets').doc(widget.petId).update({
        'imageUrl': downloadUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translations?['image_uploaded_success'] ?? 'Image uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translations?['error_uploading_image'] ?? 'Error uploading image:'} $e')),
      );
    }
  }

  void _updatePet() async {
    String name = _nameController.text;
    String dob = _dobController.text;
    String weight = _weightController.text;

    if (name.isNotEmpty && dob.isNotEmpty && weight.isNotEmpty) {
      try {
        await _firestore.collection('pets').doc(widget.petId).update({
          'name': name,
          'dob': dob,
          'weight': weight,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translations?['pet_updated_success'] ?? 'Pet updated successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_translations?['error_updating_pet'] ?? 'Error updating pet:'} $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translations?['fill_out_all_fields'] ?? 'Please fill out all fields')),
      );
    }
  }

  void _deletePet() async {
    try {
      await _firestore.collection('pets').doc(widget.petId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translations?['pet_deleted_success'] ?? 'Pet deleted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translations?['error_deleting_pet'] ?? 'Error deleting pet:'} $e')),
      );
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
        title: Text(_translations!['pet_details_title']!),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? NetworkImage(_imageUrl!)
                      : NetworkImage('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS3hTQwsrGuYW0XGXbIB4d2noVL1ZhL7llERA&s') as ImageProvider,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text(_translations!['upload_image_button']!),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: _translations!['name_label']),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _dobController,
                decoration: InputDecoration(labelText: _translations!['dob_label']),
                keyboardType: TextInputType.datetime,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(labelText: _translations!['weight_label']),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _updatePet,
                    child: Text(_translations!['save_button']!),
                  ),
                  ElevatedButton(
                    onPressed: _deletePet,
                    child: Text(_translations!['delete_button']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
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
