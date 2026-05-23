import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import 'package:petpal/new_pet_form_page.dart';
import 'package:petpal/new_task_form_page.dart';
import 'package:petpal/pet_details_page.dart';
import 'daily_tasks_list.dart';
import 'package:petpal/admin_dashboard_screen.dart' as import_admin;
import 'package:petpal/login_screen.dart' as import_login;
import 'footer.dart';
import 'package:petpal/settings_page.dart';
import 'package:petpal/main.dart';
import 'chat.dart';
import 'app_theme.dart';
import 'pet_qr_code.dart';

class HomePage extends StatefulWidget {
  final String currentLanguage;

  HomePage({required this.currentLanguage});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  Future<Map<String, String>> _getUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          String fullName = (userDoc['fullName'] as String?) ?? 'N/A';
          String profilePictureUrl =
              (userDoc['profilePictureUrl'] as String?) ?? '';
          String householdId = (userDoc['householdId'] as String?) ?? user.uid;

          return {
            'fullName': fullName,
            'profilePictureUrl': profilePictureUrl,
            'householdId': householdId,
            'favoritesLabel': 'My Pets',
            'dailyTaskLabel': 'Daily Task'
          };
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
    }
    return {
      'fullName': 'Guest',
      'profilePictureUrl': '',
      'householdId': '',
      'favoritesLabel': 'My Pets',
      'dailyTaskLabel': 'Daily Task'
    };
  }

  Stream<List<Map<String, dynamic>>> _getPetStream(String? householdId) {
    if (householdId == null) return const Stream.empty();

    return _firestore
        .collection('pets')
        .where('householdId', isEqualTo: householdId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }

  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(isDark);
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading user data'));
            } else {
              final userData = snapshot.data ??
                  {
                    'fullName': 'Guest',
                    'profilePictureUrl': '',
                    'favoritesLabel': 'My Pets',
                    'dailyTaskLabel': 'Daily Tasks',
                    'householdId': '',
                  };

              final householdId = userData['householdId'];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child:
                        _buildPremiumHeader(context, userData, isDark, isWide),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      userData['favoritesLabel']!,
                      Icons.add_circle,
                      () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewPetFormPage(
                                currentLanguage: widget.currentLanguage),
                          ),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideX(begin: -0.1, end: 0),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: isWide ? 320 : 280,
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _getPetStream(householdId),
                        builder: (context, petSnapshot) {
                          if (petSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildPetLoadingState(isDark);
                          } else if (petSnapshot.hasError) {
                            return const Center(
                                child: Text('Error loading pets'));
                          } else {
                            final pets = petSnapshot.data ?? [];
                            if (pets.isEmpty) {
                              return _buildEmptyState(isDark);
                            }
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.only(left: 24, right: 8),
                              itemCount: pets.length,
                              itemBuilder: (context, index) {
                                final pet = pets[index];
                                return _buildPremiumPetCard(
                                  context,
                                  pet,
                                  index,
                                  isDark,
                                  isWide,
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      userData['dailyTaskLabel']!,
                      Icons.add_circle_outline,
                      () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewTaskFormPage(),
                          ),
                        );
                        _refreshData();
                      },
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms)
                        .slideX(begin: -0.1, end: 0),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DailyTasksList(householdId: householdId),
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                  ),
                ],
              );
            }
          },
        ),
      ),
      bottomNavigationBar: _buildPremiumBottomNav(isDark),
    );
  }

  Widget _buildPremiumHeader(
    BuildContext context,
    Map<String, String> userData,
    bool isDark,
    bool isWide,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(isWide ? 32 : 20),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                    ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : AppTheme.mint.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.mintGradient,
                  ),
                  child: CircleAvatar(
                    radius: isWide ? 36 : 28,
                    backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                    backgroundImage: userData['profilePictureUrl'] != null &&
                            userData['profilePictureUrl']!.isNotEmpty
                        ? NetworkImage(userData['profilePictureUrl']!)
                        : const NetworkImage(
                                'https://st3.depositphotos.com/6672868/13701/v/450/depositphotos_137014128-stock-illustration-user-profile-icon.jpg')
                            as ImageProvider,
                  ),
                ).animate().scale(
                    delay: 100.ms, duration: 400.ms, curve: Curves.easeOut),
                SizedBox(width: isWide ? 24 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: isWide ? 18 : 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideX(begin: -0.2, end: 0),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.mintGradient.createShader(bounds),
                        child: Text(
                          userData['fullName']!,
                          style: TextStyle(
                            fontSize: isWide ? 28 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideX(begin: -0.2, end: 0),
                    ],
                  ),
                ),
                _buildGlowingIconButton(
                  icon: Icons.settings_rounded,
                  isDark: isDark,
                  onPressed: () {
                    final myApp = MyApp.of(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(
                          currentThemeMode: myApp?.themeMode ?? ThemeMode.light,
                          onThemeChanged: (mode) => myApp?.toggleTheme(mode),
                        ),
                      ),
                    );
                  },
                ).animate().scale(
                    delay: 400.ms, duration: 300.ms, curve: Curves.easeOut),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.2, end: 0, curve: Curves.easeOut);
  }

  Widget _buildPremiumPetCard(
    BuildContext context,
    Map<String, dynamic> pet,
    int index,
    bool isDark,
    bool isWide,
  ) {
    final petId = pet['id'] ?? '';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailsPage(
              petId: petId,
              currentLanguage: widget.currentLanguage,
            ),
          ),
        );
      },
      child: Container(
        width: isWide ? 220 : 180,
        margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: PetImage(pet: pet),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet['name'] ?? 'Unnamed',
                          style: TextStyle(
                            fontSize: isWide ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            PetQRCodeDialog.show(
                              context,
                              petId: petId,
                              petName: pet['name'] ?? 'Pet',
                              petImageUrl: pet['profilePictureUrl'],
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.mint.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.qr_code_rounded,
                              size: 18,
                              color: AppTheme.mint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.mint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pet['breed'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.2, end: 0)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData actionIcon,
    VoidCallback onAction,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.darkText,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.mint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(actionIcon, color: AppTheme.mint, size: 28),
              onPressed: onAction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isDark ? Colors.white : AppTheme.darkText,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.mint.withOpacity(0.3),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.mint),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading...',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildPetLoadingState(bool isDark) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 24),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 180,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
        ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: isDark ? Colors.white10 : Colors.white60,
            );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.mint.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 48,
              color: AppTheme.mint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No pets yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first pet to get started!',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildPremiumBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Footer(
          onTabSelected: (index) {},
          currentIndex: 0,
        ),
      ),
    );
  }
}

class PetImage extends StatelessWidget {
  final Map<String, dynamic> pet;

  const PetImage({required this.pet});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Image.network(
      pet['profilePictureUrl'] != null && pet['profilePictureUrl'].isNotEmpty
          ? pet['profilePictureUrl']
          : (pet['imageUrl'] != null && pet['imageUrl'].isNotEmpty
              ? pet['imageUrl']
              : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&q=80&w=1000'),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: isDark ? AppTheme.darkCard : Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mint),
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: isDark ? AppTheme.darkCard : Colors.grey[200],
          child: Icon(
            Icons.pets,
            size: 40,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        );
      },
    );
  }
}
