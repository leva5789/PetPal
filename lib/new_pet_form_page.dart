import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'app_toast.dart';
import 'widgets/premium_widgets.dart';

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

  final List<String> _breedList = [
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
    'Siberian Husky'
  ];

  bool _isSaving = false;

  void _savePet() async {
    if (_isSaving) return;

    final user = _auth.currentUser;

    if (user == null) {
      AppToast.error(context, 'Please sign in to add a pet');
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
      AppToast.warning(context, 'Please fill out all fields');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.exists
          ? (userDoc['fullName'] as String? ?? 'Unknown')
          : 'Unknown';
      final householdId = userDoc.exists
          ? (userDoc['householdId'] as String? ?? user.uid)
          : user.uid;

      final newPetRef = await _firestore.collection('pets').add({
        'userId': user.uid,
        'householdId': householdId,
        'userName': userName,
        'name': name,
        'dob': dob,
        'weight': weight,
        'gender': gender,
        'breed': breed,
        'profilePictureUrl': _imageUrl,
      });

      await newPetRef.update({'id': newPetRef.id});

      if (!mounted) return;

      AppToast.success(context, 'Pet added successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to add pet. Please try again.');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
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
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.peach.withOpacity(isDark ? 0.08 : 0.12),
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
                    padding: const EdgeInsets.all(20),
                    child: _buildForm(isDark),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Pet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.darkText,
                ),
              ),
              Text(
                'Tell us about your furry friend',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildForm(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.mintGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.mint.withOpacity(0.4),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Icon(Icons.pets_rounded, size: 48, color: Colors.white),
        ).animate().scale(duration: 400.ms).fadeIn(),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Pet Name',
                icon: Icons.edit_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildDateField(isDark),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _weightController,
                label: 'Weight (kg)',
                icon: Icons.monitor_weight_rounded,
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Gender',
                icon: Icons.wc_rounded,
                value: _selectedGender,
                items: ['Male', 'Female'],
                onChanged: (v) => setState(() => _selectedGender = v),
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Breed',
                icon: Icons.category_rounded,
                value: _selectedBreed,
                items: _breedList,
                onChanged: (v) => setState(() => _selectedBreed = v),
                isDark: isDark,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AnimatedPressButton(
                  onPressed: _savePet,
                  isLoading: _isSaving,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Save Pet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.darkText,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[500],
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.mint, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return GestureDetector(
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
        child: TextField(
          controller: _dobController,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.darkText,
          ),
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            labelStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            prefixIcon: Icon(
              Icons.calendar_today_rounded,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            filled: true,
            fillColor:
                isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.mint, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.darkText,
      ),
      dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[500],
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.mint, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
