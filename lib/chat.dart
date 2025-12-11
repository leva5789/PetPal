import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'footer.dart';
import 'homepage.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  bool _isLoadingPremium = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _initPremiumAndWelcome();
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

      // Ha prémium, akkor ugyanúgy jöhet az első AI üzenet, mint eddig
      if (isPremium) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _messages.add({
              'sender': 'ai',
              'text':
              'Szia! Az állattartásban segítek. Használhatod a /addtask parancsot a napi feladatok hozzáadásához. Például: /addtask Kutyasétáltatás 2025-01-03 Rex.',
            });
          });
        });
      }
    } catch (e) {
      // Hiba esetén inkább letiltjuk a prémium funkciót, hogy ne szálljon el az app
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Pet "$petName" does not exist.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'userId': user.uid,
        'description': description,
        'date': DateTime.parse(date),
        'petName': petName,
        'completed': false,
      });

      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Task successfully added for "$petName" on $date.',
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not add task. Please try again.'),
        ),
      );
    }
  }

  void _handleCommand(String userMessage) {
    if (userMessage.startsWith('/addtask')) {
      final parts = userMessage
          .replaceFirst('/addtask', '')
          .trim()
          .split(RegExp(r'\s+'));

      if (parts.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Invalid task format. Use /addtask description YYYY-MM-DD petName.',
            ),
          ),
        );
        return;
      }

      final description = parts[0];
      final date = parts[1];
      final petName = parts[2];

      _addTask(description, date, petName);
    } else {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Sorry, I did not understand that command.',
        });
      });
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
    });
    _messageController.clear();

    if (userMessage.startsWith('/addtask')) {
      _handleCommand(userMessage);
    } else {
      try {
        final aiResponse = await _sendMessageToAI(userMessage);
        if (!mounted) return;
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': aiResponse,
          });
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': 'Error: Unable to fetch response.',
          });
        });
      }
    }
  }

  /// Ezzel hívod most a Firebase Functions-ön keresztül az OpenAI-t
  Future<String> _sendMessageToAI(String userMessage) async {
    final url = Uri.parse(
      'https://petpalchat-md6ydt4via-uc.a.run.app',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'message': userMessage}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['reply'] as String;
    } else {
      throw Exception(
        'Failed to fetch AI response: ${response.body}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Amíg töltjük, hogy prémium-e:
    if (_isLoadingPremium) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Ha NEM prémium: teljesen fehér képernyő, csak szöveggel
    if (!_isPremium) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Chat with AI'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Ez a funkció csak a prémium felhasználóknak elérhető.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
        bottomNavigationBar: Footer(
          onTabSelected: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                    currentLanguage: 'hu',
                  ),
                ),
              );
            }
          },
          currentIndex: 1,
        ),
      );
    }

    // Ha prémium: mehet a régi chat UI
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Chat with AI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      message['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Footer(
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  currentLanguage: 'hu',
                ),
              ),
            );
          }
        },
        currentIndex: 1,
      ),
    );
  }
}
