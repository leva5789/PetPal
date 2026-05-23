import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class PetPublicProfilePage extends StatefulWidget {
  final String petId;

  const PetPublicProfilePage({super.key, required this.petId});

  @override
  State<PetPublicProfilePage> createState() => _PetPublicProfilePageState();
}

class _PetPublicProfilePageState extends State<PetPublicProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _petData;
  Map<String, dynamic>? _ownerData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final petDoc =
          await _firestore.collection('pets').doc(widget.petId).get();

      if (!petDoc.exists) {
        setState(() {
          _error = 'Pet not found';
          _isLoading = false;
        });
        return;
      }

      final petData = petDoc.data()!;

      final ownerId = petData['userId'] as String?;
      Map<String, dynamic>? ownerData;

      if (ownerId != null) {
        final ownerDoc =
            await _firestore.collection('users').doc(ownerId).get();
        if (ownerDoc.exists) {
          ownerData = ownerDoc.data();
        }
      }

      if (mounted) {
        setState(() {
          _petData = petData;
          _ownerData = ownerData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading pet data';
          _isLoading = false;
        });
      }
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'Unknown';
    try {
      final birthDate = DateTime.parse(dob);
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        years--;
      }
      if (years < 1) {
        int months =
            (now.year - birthDate.year) * 12 + now.month - birthDate.month;
        return '$months months';
      }
      return '$years years';
    } catch (_) {
      return dob;
    }
  }

  Future<void> _callOwner() async {
    final phone = _ownerData?['phoneNumber'] as String?;
    if (phone == null || phone.isEmpty) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.mint),
        ),
      );
    }

    if (_error != null || _petData == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Pet not found',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white : AppTheme.darkText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final petName = _petData!['name'] ?? 'Unknown Pet';
    final petImage =
        _petData!['profilePictureUrl'] ?? 'https://via.placeholder.com/300';
    final breed = _petData!['breed'] ?? 'Unknown';
    final gender = _petData!['gender'] ?? 'Unknown';
    final dob = _petData!['dob'] as String?;
    final ownerName = _ownerData?['fullName'] ?? 'Unknown Owner';
    final ownerPhone = _ownerData?['phoneNumber'] as String?;

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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.mintGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.pets_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'PetPal',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.mint.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.mintGradient,
                      ),
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor:
                            isDark ? AppTheme.darkCard : Colors.white,
                        backgroundImage: NetworkImage(petImage),
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  Text(
                    petName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.darkText,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.mint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      breed,
                      style: const TextStyle(
                        color: AppTheme.mint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.cake_rounded,
                            label: 'Age',
                            value: _calculateAge(dob),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            icon: gender == 'Male'
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            label: 'Gender',
                            value: gender,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 32),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.peach.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: AppTheme.peach,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Owner',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    ownerName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (ownerPhone != null && ownerPhone.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _callOwner,
                              icon: const Icon(Icons.call_rounded,
                                  color: Colors.white),
                              label: Text(
                                'Call $ownerPhone',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.mint,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 32),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Found this pet? Please call the owner!',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.amber[200]
                                  : Colors.amber[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.mint, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
