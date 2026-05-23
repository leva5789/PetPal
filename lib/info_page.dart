import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'app_theme.dart';
import 'footer.dart';
import 'widgets/premium_widgets.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _petInfos = [];
  String? _dailyTip;

  static List<Map<String, dynamic>>? _cachedPetInfos;
  static String? _cachedDailyTip;

  static const String _generatePetInfoUrl =
      'https://generatepetinfo-md6ydt4via-uc.a.run.app';
  static const String _generateDailyTipUrl =
      'https://generatedailytip-md6ydt4via-uc.a.run.app';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (_cachedPetInfos != null && _cachedDailyTip != null) {
      if (mounted) {
        setState(() {
          _petInfos = _cachedPetInfos!;
          _dailyTip = _cachedDailyTip!;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final petsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (petsSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _petInfos = [];
          _dailyTip = "Add a pet to get personalized tips!";
        });
        return;
      }

      final recentTasksSnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      final recentTasks = recentTasksSnap.docs.map((d) {
        final data = d.data();
        return "${data['description']} (${data['type']})";
      }).toList();

      final firstPetName =
          petsSnapshot.docs.first['name'] as String? ?? 'your pet';

      final tipFuture = _fetchDailyTip(firstPetName, recentTasks);

      final petInfoFutures = petsSnapshot.docs.map((doc) async {
        final data = doc.data();
        final breed = data['breed'] as String? ?? 'Unknown';
        final name = data['name'] as String? ?? 'Pet';

        if (breed.isEmpty || breed == 'Unknown') return null;

        return _fetchPetInfo(breed, name);
      }).toList();

      final results = await Future.wait([tipFuture, ...petInfoFutures]);

      _dailyTip = results[0] as String?;

      _petInfos = [];
      for (int i = 1; i < results.length; i++) {
        if (results[i] != null) {
          _petInfos.add(results[i] as Map<String, dynamic>);
        }
      }

      _cachedPetInfos = _petInfos;
      _cachedDailyTip = _dailyTip;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading info page: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Unable to load insights. Please try again later.";
        });
      }
    }
  }

  Future<String> _fetchDailyTip(
      String petName, List<String> recentTasks) async {
    try {
      final response = await http.post(
        Uri.parse(_generateDailyTipUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'petName': petName,
          'recentTasks': recentTasks,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tip'] as String;
      }
    } catch (e) {
      print("Daily Tip Error: $e");
    }
    return "Remember to give your pet lots of love today! 🐾";
  }

  Future<Map<String, dynamic>?> _fetchPetInfo(String breed, String name) async {
    try {
      final response = await http.post(
        Uri.parse(_generatePetInfoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'breed': breed,
          'petName': name,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Pet Info Error ($breed): $e");
    }
    return null;
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
                      : _errorMessage != null
                          ? EmptyState(
                              icon: Icons.error_outline_rounded,
                              title: 'Oops!',
                              subtitle: _errorMessage,
                              actionLabel: 'Retry',
                              onAction: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                  _cachedPetInfos = null;
                                  _cachedDailyTip = null;
                                });
                                _loadAllData();
                              },
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                setState(() {
                                  _cachedPetInfos = null;
                                  _cachedDailyTip = null;
                                });
                                await _loadAllData();
                              },
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    if (_dailyTip != null)
                                      _buildDailyTipToken(_dailyTip!),
                                    const SizedBox(height: 24),
                                    _buildSectionTitle('Breed Insights',
                                        Icons.pets_rounded, isDark),
                                    if (_petInfos.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Text(
                                          "No breed info available. Ensure your pets have a breed set!",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ..._petInfos
                                        .map((info) =>
                                            _buildPetInfoCard(info, isDark))
                                        .toList(),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
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
                child: const Icon(
                  Icons.lightbulb_rounded,
                  size: 20,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Insights',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.darkText,
                    ),
                  ),
                  Text(
                    'Daily tips & knowledge',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _cachedPetInfos = null;
                _cachedDailyTip = null;
              });
              _loadAllData();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: isDark ? Colors.white : AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildDailyTipToken(String tip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.mintGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.mint.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Daily Tip",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tip,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 500.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.mint),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoCard(Map<String, dynamic> info, bool isDark) {
    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets_rounded, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "About ${info['breedName'] ?? 'Your Dog'}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            info['description'] ?? '',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.6,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.favorite_rounded, "Care",
              info['care_instructions'], isDark),
          const SizedBox(height: 16),
          _buildInfoRow(
              Icons.lightbulb_rounded, "Fun Fact", info['fun_fact'], isDark),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoRow(
      IconData icon, String title, String? content, bool isDark) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.mint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.darkText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Consulting the experts... 🧠",
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
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
          currentIndex: 4,
        ),
      ),
    );
  }
}
