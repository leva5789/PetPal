import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'app_theme.dart';
import 'app_toast.dart';
import 'widgets/premium_widgets.dart';

class NewTaskFormPage extends StatefulWidget {
  @override
  _NewTaskFormPageState createState() => _NewTaskFormPageState();
}

class _NewTaskFormPageState extends State<NewTaskFormPage> {
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedPet;
  bool _isSubmitting = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _categorizeFunctionUrl =
      'https://categorizetask-md6ydt4via-uc.a.run.app';

  Future<String?> _getHouseholdId(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? (doc['householdId'] as String?) : null;
  }

  Future<List<String>> _getUserPets() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String? householdId = await _getHouseholdId(user.uid);

      QuerySnapshot petQuery;
      if (householdId != null) {
        petQuery = await _firestore
            .collection('pets')
            .where('householdId', isEqualTo: householdId)
            .get();
      } else {
        petQuery = await _firestore
            .collection('pets')
            .where('userId', isEqualTo: user.uid)
            .get();
      }
      return petQuery.docs.map((doc) => doc['name'] as String).toList();
    }
    return [];
  }

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
      }
    } catch (e) {
      print('categorizeTask exception: $e');
    }
    return 'not_understood';
  }

  void _submitTask() async {
    if (_isSubmitting) return;

    User? user = _auth.currentUser;
    final description = _descriptionController.text.trim();

    if (user != null &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedPet != null &&
        description.isNotEmpty) {
      setState(() => _isSubmitting = true);

      String? householdId = await _getHouseholdId(user.uid);

      final finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final type = await _categorizeTask(description);

      int xpReward = 20;
      String cleanType = type.toLowerCase().trim();

      if (cleanType == 'not_understood' || cleanType == 'other') {
        final lowerDesc = description.toLowerCase();
        if (lowerDesc.contains('séta') ||
            lowerDesc.contains('walk') ||
            lowerDesc.contains('futás') ||
            lowerDesc.contains('játék')) {
          cleanType = 'activity';
        } else if (lowerDesc.contains('etet') ||
            lowerDesc.contains('food') ||
            lowerDesc.contains('víz') ||
            lowerDesc.contains('táp')) {
          cleanType = 'food';
        } else if (lowerDesc.contains('orvos') ||
            lowerDesc.contains('oltás') ||
            lowerDesc.contains('gyógyszer') ||
            lowerDesc.contains('vet')) {
          cleanType = 'health';
        }
      }

      switch (cleanType) {
        case 'food':
          xpReward = 10;
          break;
        case 'activity':
          xpReward = 50;
          break;
        case 'health':
          xpReward = 100;
          break;
      }

      await _firestore.collection('tasks').add({
        'userId': user.uid,
        'householdId': householdId ?? user.uid,
        'description': description,
        'type': cleanType,
        'xpReward': xpReward,
        'date': finalDateTime,
        'petName': _selectedPet,
        'completed': false,
      });

      if (context.mounted) Navigator.pop(context);
    } else {
      AppToast.warning(context, 'Please fill all fields');
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
                    AppTheme.peach.withOpacity(isDark ? 0.1 : 0.15),
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
                    AppTheme.mint.withOpacity(isDark ? 0.08 : 0.12),
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
                'New Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.darkText,
                ),
              ),
              Text(
                'Add a task for your pet',
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
            gradient: AppTheme.peachGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.peach.withOpacity(0.4),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Icon(Icons.add_task, size: 48, color: Colors.white),
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
                controller: _descriptionController,
                label: 'Description',
                hint: 'e.g., Walk the dog',
                icon: Icons.description_rounded,
                isDark: isDark,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              _buildDateField(isDark),
              const SizedBox(height: 20),
              _buildTimeField(isDark),
              const SizedBox(height: 20),
              _buildPetDropdown(isDark),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AnimatedPressButton(
                  onPressed: _submitTask,
                  isLoading: _isSubmitting,
                  gradient: AppTheme.peachGradient,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_task_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Add Task',
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
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.darkText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
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
          borderSide: const BorderSide(color: AppTheme.peach, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? 'Select Due Date'
                  : _selectedDate!.toLocal().toString().split(' ')[0],
              style: TextStyle(
                color: _selectedDate == null
                    ? (isDark ? Colors.grey[400] : Colors.grey[600])
                    : (isDark ? Colors.white : AppTheme.darkText),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(bool isDark) {
    return GestureDetector(
      onTap: () async {
        TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Text(
              _selectedTime == null
                  ? 'Select Due Time'
                  : _selectedTime!.format(context),
              style: TextStyle(
                color: _selectedTime == null
                    ? (isDark ? Colors.grey[400] : Colors.grey[600])
                    : (isDark ? Colors.white : AppTheme.darkText),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetDropdown(bool isDark) {
    return FutureBuilder<List<String>>(
      future: _getUserPets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pets_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
                const SizedBox(width: 12),
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          );
        }

        final petNames = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          value: _selectedPet,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.darkText,
          ),
          dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
          decoration: InputDecoration(
            labelText: 'Select Pet',
            labelStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            prefixIcon: Icon(
              Icons.pets_rounded,
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
              borderSide: const BorderSide(color: AppTheme.peach, width: 2),
            ),
          ),
          items: petNames.map((petName) {
            return DropdownMenuItem(
              value: petName,
              child: Text(petName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedPet = value);
          },
        );
      },
    );
  }
}
