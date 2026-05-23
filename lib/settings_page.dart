import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:ui';
import 'app_theme.dart';
import 'app_toast.dart';
import 'login_screen.dart';
import 'widgets/premium_widgets.dart';

class SettingsPage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const SettingsPage({
    Key? key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.currentThemeMode == ThemeMode.dark;
  }

  void _toggleTheme(bool value) {
    setState(() => _isDarkMode = value);
    widget.onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
    _saveThemePreference(value);
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'themePreference': isDark ? 'dark' : 'light',
      });
    }
  }

  Future<void> _kickMember(String memberId, String memberName) async {
    try {
      await _firestore.collection('users').doc(memberId).update({
        'householdId': memberId,
      });
      if (mounted) {
        AppToast.success(context, '$memberName removed from household');
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to remove member');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
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
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildAccountCard(user, isDark),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Appearance', Icons.palette_rounded),
                      _buildAppearanceCard(isDark),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                          'Family & Household', Icons.family_restroom_rounded),
                      _buildHouseholdCard(user, isDark),
                      const SizedBox(height: 20),
                      if (user != null) _buildMembersSection(user, isDark),
                      _buildLogoutCard(isDark),
                      const SizedBox(height: 32),
                    ],
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
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.darkText,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.mint,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(User? user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(
                user?.photoURL ??
                    'https://st3.depositphotos.com/6672868/13701/v/450/depositphotos_137014128-stock-illustration-user-profile-icon.jpg',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(user?.uid).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final int totalXp = (data?['totalXp'] as int?) ?? 0;
                    final int level = (data?['level'] as int?) ?? 1;
                    final int currentLevelXp = totalXp % 1000;
                    final double progress = currentLevelXp / 1000.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Level $level',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '$currentLevelXp / 1000 XP',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildAppearanceCard(bool isDark) {
    return AnimatedCard(
      onTap: () => _toggleTheme(!_isDarkMode),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: _isDarkMode ? Colors.amber : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isDarkMode
                      ? 'Currently using dark theme'
                      : 'Currently using light theme',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDarkMode,
            onChanged: _toggleTheme,
            activeColor: AppTheme.mint,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildHouseholdCard(User? user, bool isDark) {
    return AnimatedCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.mint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.vpn_key_rounded, color: AppTheme.mint),
            ),
            title: const Text('My Household ID'),
            subtitle: FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(user?.uid).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading...');
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final hId = data?['householdId'] ?? 'N/A';
                return Text(
                  hId,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.mint : AppTheme.darkText,
                  ),
                );
              },
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconAction(
                  Icons.fullscreen_rounded,
                  isDark,
                  () async {
                    final doc = await _firestore
                        .collection('users')
                        .doc(user?.uid)
                        .get();
                    final hId = doc['householdId'] as String? ?? 'N/A';
                    if (context.mounted) _showBigIdDialog(context, hId);
                  },
                ),
                const SizedBox(width: 8),
                _buildIconAction(
                  Icons.copy_rounded,
                  isDark,
                  () async {
                    final doc = await _firestore
                        .collection('users')
                        .doc(user?.uid)
                        .get();
                    final hId = doc['householdId'] as String?;
                    if (hId != null) {
                      await Clipboard.setData(ClipboardData(text: hId));
                      if (context.mounted) {
                        AppToast.info(context, 'ID copied!');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
          ),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.peach.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.group_add_rounded, color: AppTheme.peach),
            ),
            title: const Text('Join a Household'),
            subtitle: const Text('Enter ID to sync with family'),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            onTap: () => _showJoinHouseholdDialog(context, user),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildIconAction(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildMembersSection(User user, bool isDark) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final householdId = userData?['householdId'];

        if (householdId == null) return const SizedBox();
        final isLeader = householdId == user.uid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Household Members', Icons.people_rounded),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('householdId', isEqualTo: householdId)
                  .snapshots(),
              builder: (context, membersSnap) {
                if (membersSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = membersSnap.data?.docs ?? [];
                if (members.isEmpty) {
                  return AnimatedCard(
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No members found.'),
                      ),
                    ),
                  );
                }

                return AnimatedCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: members.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final memberId = doc.id;
                      final name = data['fullName'] ?? 'Unknown';
                      final isMe = memberId == user.uid;
                      final isMemberLeader = memberId == householdId;

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isMemberLeader
                                ? Border.all(color: AppTheme.mint, width: 2)
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              data['profilePictureUrl'] ??
                                  'https://st3.depositphotos.com/6672868/13701/v/450/depositphotos_137014128-stock-illustration-user-profile-icon.jpg',
                            ),
                          ),
                        ),
                        title: Text(
                          name + (isMe ? ' (You)' : ''),
                          style: TextStyle(
                            fontWeight:
                                isMe ? FontWeight.bold : FontWeight.normal,
                            color: isDark ? Colors.white : AppTheme.darkText,
                          ),
                        ),
                        subtitle: Text(
                          isMemberLeader ? '👑 Leader' : 'Member',
                          style: TextStyle(
                            fontSize: 12,
                            color: isMemberLeader ? AppTheme.mint : Colors.grey,
                          ),
                        ),
                        trailing: (isLeader && !isMe)
                            ? GestureDetector(
                                onTap: () => _kickMember(memberId, name),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_remove_rounded,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              )
                            : null,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildLogoutCard(bool isDark) {
    return AnimatedCard(
      onTap: () async {
        try {
          final googleSignIn = GoogleSignIn();
          if (await googleSignIn.isSignedIn()) {
            await googleSignIn.signOut();
          }

          await _auth.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              FadePageRoute(page: LoginScreen()),
              (route) => false,
            );
          }
        } catch (e) {
          if (mounted) {
            AppToast.error(context, 'Failed to log out');
          }
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.red),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.red.withOpacity(0.5),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  void _showBigIdDialog(BuildContext context, String id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.vpn_key_rounded,
                    color: AppTheme.mint, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Household ID',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  id,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isDark ? Colors.white : AppTheme.darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share this code with your family members',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: id));
                        Navigator.pop(context);
                        AppToast.info(context, 'ID copied!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mint,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Copy',
                          style: TextStyle(color: Colors.white)),
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

  void _showJoinHouseholdDialog(BuildContext context, User? user) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.peach.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add_rounded,
                      color: AppTheme.peach, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'Join Household',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste the household ID shared by your family',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  PremiumTextField(
                    controller: controller,
                    label: 'Household ID',
                    hint: 'e.g. 5G9xyz123...',
                    prefixIcon: Icons.vpn_key_rounded,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            String newId = controller.text
                                .trim()
                                .replaceAll(RegExp(r'\s+'), '');
                            if (newId.isEmpty || user == null) return;

                            setState(() => isLoading = true);

                            try {
                              final targetUserDoc = await _firestore
                                  .collection('users')
                                  .doc(newId)
                                  .get();

                              if (!targetUserDoc.exists) {
                                Navigator.pop(context);
                                AppToast.error(
                                    context, 'Household ID not found');
                                return;
                              }

                              await _firestore
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({
                                'householdId': newId,
                              });

                              Navigator.pop(context);
                              AppToast.success(context, 'Joined household!');
                              this.setState(() {});
                            } catch (e) {
                              Navigator.pop(context);
                              AppToast.error(
                                  context, 'Failed to join household');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.mint,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Join',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
