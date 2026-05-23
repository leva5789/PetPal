import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'footer.dart';
import 'weightstats.dart';
import 'app_theme.dart';
import 'widgets/premium_widgets.dart';

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _householdId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHouseholdId();
  }

  Future<void> _loadHouseholdId() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _householdId =
              userDoc.exists ? (userDoc['householdId'] as String?) : null;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _getPetsStream() {
    final user = _auth.currentUser;
    if (user == null || _householdId == null) return const Stream.empty();

    return _firestore
        .collection('pets')
        .where('householdId', isEqualTo: _householdId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Stream<Map<String, int>> _getTaskStatsStream(String petName) {
    final user = _auth.currentUser;
    if (user == null || _householdId == null) return const Stream.empty();

    return _firestore
        .collection('tasks')
        .where('householdId', isEqualTo: _householdId)
        .where('petName', isEqualTo: petName)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs;
      final total = tasks.length;
      final completed = tasks.where((doc) {
        final data = doc.data();
        return data['completed'] == true;
      }).length;

      return {
        'total': total,
        'completed': completed,
        'rate': total > 0 ? ((completed / total) * 100).round() : 0,
      };
    });
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
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(isDark)
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _getPetsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingState(isDark);
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(color: Colors.red[400]),
                                ),
                              );
                            } else {
                              final pets = snapshot.data ?? [];
                              return pets.isEmpty
                                  ? EmptyState(
                                      icon: Icons.pets_rounded,
                                      title: 'No pets found',
                                      subtitle:
                                          'Add a pet to start tracking stats!',
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(20),
                                      itemCount: pets.length,
                                      itemBuilder: (context, index) {
                                        final pet = pets[index];
                                        return _buildPetStatsCard(
                                            pet, isDark, index);
                                      },
                                    );
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
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
                'Pet Statistics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.darkText,
                ),
              ),
              Text(
                'Track progress and health',
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

  Widget _buildPetStatsCard(Map<String, dynamic> pet, bool isDark, int index) {
    final petName = pet['name'] ?? 'Unnamed';
    final petWeight = double.tryParse(pet['weight']?.toString() ?? '0') ?? 0.0;
    final petPicture =
        pet['profilePictureUrl'] ?? 'https://via.placeholder.com/150';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          FadePageRoute(
            page: WeightStatsPage(
              petId: pet['id'],
              petName: petName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.mintGradient,
              ),
              child: Hero(
                tag: 'pet_img_$petName',
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                  backgroundImage: NetworkImage(petPicture),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        petName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.darkText,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.mint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$petWeight kg',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<Map<String, int>>(
                    stream: _getTaskStatsStream(petName),
                    builder: (context, taskSnapshot) {
                      final stats = taskSnapshot.data ??
                          {'total': 0, 'completed': 0, 'rate': 0};
                      final completionRate = stats['rate'] ?? 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Task Completion',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                '$completionRate%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.mint,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: 8,
                                width:
                                    (MediaQuery.of(context).size.width - 172) *
                                        (completionRate / 100),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.mintGradient,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.mint.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
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
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading stats...',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Footer(
          onTabSelected: (index) {},
          currentIndex: 2,
        ),
      ),
    );
  }
}
