import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'footer.dart';
import 'homepage.dart';
import 'app_theme.dart';
import 'app_toast.dart';
import 'widgets/premium_widgets.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  bool _isLoadingPremium = true;
  bool _isPremium = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initPremiumAndWelcome();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initPremiumAndWelcome() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isPremium = false;
          _isLoadingPremium = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      final isPremium = (data?['isPremium'] as bool?) ?? false;

      setState(() {
        _isPremium = isPremium;
        _isLoadingPremium = false;
      });

      if (isPremium) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _messages.add({
              'sender': 'ai',
              'text':
                  'Szia! 👋 Miben segíthetek ma? Használhatod a /addtask parancsot feladatok hozzáadásához.',
            });
          });
        });
      }
    } catch (e) {
      setState(() {
        _isPremium = false;
        _isLoadingPremium = false;
      });
    }
  }

  Future<List<String>> _getUserPets() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot petQuery = await FirebaseFirestore.instance
          .collection('pets')
          .where('userId', isEqualTo: user.uid)
          .get();
      return petQuery.docs.map((doc) => doc['name'] as String).toList();
    }
    return [];
  }

  Future<void> _addTask(String description, String date, String petName) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pets = await _getUserPets();

    if (!pets.contains(petName)) {
      AppToast.warning(context, 'Pet "$petName" does not exist');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'userId': user.uid,
        'description': description,
        'date': date,
        'petName': petName,
        'type': 'general',
        'completed': false,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((d) async {
        final householdId = (d.data()?['householdId'] as String?) ?? user.uid;
        await FirebaseFirestore.instance.collection('tasks').doc().set({
          'userId': user.uid,
          'householdId': householdId,
          'description': description,
          'date': date,
          'petName': petName,
          'type': 'general',
          'completed': false,
        });
      });

      setState(() {
        _messages.add({
          'sender': 'ai',
          'text':
              '✅ Feladat hozzáadva: "$description" - $petName számára, dátum: $date.',
        });
      });
    } catch (e) {
      AppToast.error(context, 'Failed to add task');
    }
  }

  void _handleCommand(String command) {
    if (command.startsWith('/addtask')) {
      final parts = command.replaceFirst('/addtask', '').trim().split(' ');
      if (parts.length >= 3) {
        final description = parts.sublist(0, parts.length - 2).join(' ');
        final date = parts[parts.length - 2];
        final petName = parts.last;
        _addTask(description, date, petName);
      } else {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text':
                '❌ Helytelen formátum. Használd így: /addtask [leírás] [dátum] [kisállat neve]',
          });
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': userMessage,
      });
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    if (userMessage.startsWith('/addtask')) {
      setState(() {
        _isTyping = false;
      });
      _handleCommand(userMessage);
    } else {
      try {
        final aiResponse = await _sendMessageToAI(userMessage);
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add({
            'sender': 'ai',
            'text': aiResponse,
          });
        });
        _scrollToBottom();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add({
            'sender': 'ai',
            'text': '❌ Hiba történt. Próbáld újra később.',
          });
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _sendMessageToAI(String userMessage) async {
    final url = Uri.parse('https://petpalchat-md6ydt4via-uc.a.run.app');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'message': userMessage}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['reply'] as String;
    } else {
      throw Exception('Failed to fetch AI response');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingPremium) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Container(
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
        ),
      );
    }

    if (!_isPremium) {
      return _buildPremiumUpsell(isDark);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
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
          Column(
            children: [
              _buildChatHeader(isDark),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _buildTypingIndicator(isDark);
                    }

                    final message = _messages[index];
                    final isUser = message['sender'] == 'user';

                    return _buildMessageBubble(
                      message['text'] ?? '',
                      isUser,
                      isDark,
                      index,
                    );
                  },
                ),
              ),
              _buildInputArea(isDark),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildChatHeader(bool isDark) {
    return SafeArea(
      bottom: false,
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.mintGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PetPal AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.darkText,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.mint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildMessageBubble(String text, bool isUser, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.mintGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.mintGradient : null,
                color:
                    isUser ? null : (isDark ? AppTheme.darkCard : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppTheme.mint.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : AppTheme.darkText),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * (index % 5)))
        .fadeIn(duration: 300.ms)
        .slideX(begin: isUser ? 0.2 : -0.2, end: 0);
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.mintGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildDot(index, isDark),
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildDot(int index, bool isDark) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.mint.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.3, 1.3),
          duration: 400.ms,
          delay: Duration(milliseconds: index * 150),
        )
        .then()
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          duration: 400.ms,
        );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.darkText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Írj üzenetet...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppTheme.mintGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.mint.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumUpsell(bool isDark) {
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
                    Colors.amber.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
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
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: isDark ? Colors.white : AppTheme.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.5),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.stars_rounded,
                                size: 64, color: Colors.white),
                          ).animate().scale(duration: 500.ms).fadeIn(),
                          const SizedBox(height: 32),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ).createShader(bounds),
                            child: const Text(
                              'Premium Feature',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 16),
                          Text(
                            'Szerezz hozzáférést a személyre szabott AI asszisztenshez, amely segít a kisállatod gondozásában.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 40),
                          AnimatedPressButton(
                            onPressed: () {},
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.diamond_rounded,
                                    color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Upgrade to Premium',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.2, end: 0),
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
          onTabSelected: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                FadePageRoute(page: HomePage(currentLanguage: 'hu')),
              );
            }
          },
          currentIndex: 1,
        ),
      ),
    );
  }
}
