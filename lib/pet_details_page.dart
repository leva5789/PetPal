import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'app_toast.dart';
import 'widgets/premium_widgets.dart';

class PetDetailsPage extends StatefulWidget {
  final String petId;
  final String currentLanguage;

  const PetDetailsPage({
    super.key,
    required this.petId,
    required this.currentLanguage,
  });

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
  bool _isSaving = false;
  String? _imageUrl;
  String? _breed;
  String? _originalName;
  Uint8List? _imageBytes;

  Map<String, String> _translations = {};

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _loadPetDetails();
  }

  Future<void> _loadTranslations() async {
    try {
      String lang =
          widget.currentLanguage.isNotEmpty ? widget.currentLanguage : 'hu';
      DocumentSnapshot doc =
          await _firestore.collection('translations').doc(lang).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _translations = Map<String, String>.from(doc.data() as Map);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading translations: $e');
    }
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }

  Future<void> _loadPetDetails() async {
    try {
      DocumentSnapshot petDoc =
          await _firestore.collection('pets').doc(widget.petId).get();

      if (petDoc.exists && petDoc.data() != null) {
        final petData = petDoc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = petData['name']?.toString() ?? '';
          _originalName = petData['name']?.toString();
          _dobController.text = petData['dob']?.toString() ?? '';
          _weightController.text = petData['weight']?.toString() ?? '';

          _imageUrl =
              (petData['imageUrl'] ?? petData['profilePictureUrl'])?.toString();
          _breed = petData['breed']?.toString();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          AppToast.error(context, 'Pet not found');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, 'Failed to load pet details');
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

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

      if (mounted) {
        AppToast.success(context, 'Photo uploaded!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to upload photo');
      }
    }
  }

  void _updatePet() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final weight = _weightController.text.trim();

    if (name.isNotEmpty &&
        dob.isNotEmpty &&
        weight.isNotEmpty &&
        _breed != null &&
        _breed!.isNotEmpty) {
      setState(() => _isSaving = true);

      try {
        final batch = _firestore.batch();
        final user = _auth.currentUser;

        final petRef = _firestore.collection('pets').doc(widget.petId);
        batch.update(petRef, {
          'name': name,
          'dob': dob,
          'weight': weight,
          'breed': _breed,
        });

        if (user != null && _originalName != null && name != _originalName) {
          final tasksQuery = await _firestore
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .where('petName', isEqualTo: _originalName)
              .get();

          for (final doc in tasksQuery.docs) {
            batch.update(doc.reference, {'petName': name});
          }
        }

        await batch.commit();

        setState(() => _originalName = name);

        if (!mounted) return;

        AppToast.success(context, 'Pet updated!');
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        AppToast.error(context, 'Failed to update pet');
        setState(() => _isSaving = false);
      }
    } else {
      AppToast.warning(context, 'Please fill out all fields');
    }
  }

  void _deletePet() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final batch = _firestore.batch();
      final user = _auth.currentUser;

      if (user != null && _originalName != null) {
        final tasksQuery = await _firestore
            .collection('tasks')
            .where('userId', isEqualTo: user.uid)
            .where('petName', isEqualTo: _originalName)
            .get();
        for (final doc in tasksQuery.docs) {
          batch.delete(doc.reference);
        }
      }

      final weightQuery = await _firestore
          .collection('pets')
          .doc(widget.petId)
          .collection('weightHistory')
          .get();
      for (final doc in weightQuery.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_firestore.collection('pets').doc(widget.petId));
      await batch.commit();

      if (_imageUrl != null &&
          _imageUrl!.isNotEmpty &&
          _imageUrl!.contains('firebase_storage')) {
        try {
          await _storage.refFromURL(_imageUrl!).delete();
        } catch (e) {
          debugPrint('Error deleting image from storage: $e');
        }
      }

      if (!mounted) return;

      AppToast.success(context, 'Pet deleted');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to delete pet');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.mint)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageProvider = (_imageUrl != null && _imageUrl!.isNotEmpty)
        ? NetworkImage(_imageUrl!)
        : (_imageBytes != null
            ? MemoryImage(_imageBytes!)
            : const NetworkImage(
                    'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&q=80&w=1000')
                as ImageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.mint.withOpacity(isDark ? 0.1 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildProfileImage(imageProvider, isDark),
                        const SizedBox(height: 32),
                        _buildEditForm(isDark),
                        const SizedBox(height: 32),
                        _buildActionButtons(isDark),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? Colors.white : AppTheme.darkText,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            translate('pet_details'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.darkText,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildProfileImage(ImageProvider imageProvider, bool isDark) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 160,
            height: 160,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.mintGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.mint.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 10,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildEditForm(bool isDark) {
    return AnimatedCard(
      child: Column(
        children: [
          PremiumTextField(
            controller: _nameController,
            label: translate('pet_name'),
            prefixIcon: Icons.pets_rounded,
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            },
            child: AbsorbPointer(
              child: PremiumTextField(
                controller: _dobController,
                label: translate('date_of_birth'),
                prefixIcon: Icons.calendar_today_rounded,
              ),
            ),
          ),
          const SizedBox(height: 20),
          PremiumTextField(
            controller: _weightController,
            label: translate('weight'),
            prefixIcon: Icons.monitor_weight_rounded,
            suffixText: 'kg',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.category_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translate('breed'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _breed ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : _deletePet,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              foregroundColor: Colors.redAccent,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline_rounded),
                      const SizedBox(width: 8),
                      Text(translate('delete')),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedPressButton(
            onPressed: _updatePet,
            isLoading: _isSaving,
            gradient: AppTheme.mintGradient,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  translate('save'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }
}
