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
  final String _apiKey = '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';

  @override
  void initState() {
    super.initState();
    // Add initial AI message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Szia! Az állattartásban segítek. Használhatod a /addtask parancsot a napi feladatok hozzáadásához. Például: /addtask Kutyasétáltatás 2025-01-03 Rex.',
        });
      });
    });
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

      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Task successfully added for "$petName" on $date.',
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not add task. Please try again.')),
      );
    }
  }

  void _handleCommand(String userMessage) {
    if (userMessage.startsWith('/addtask')) {
      final parts = userMessage.replaceFirst('/addtask', '').trim().split(RegExp(r'\s+'));

      if (parts.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Invalid task format. Use /addtask description YYYY-MM-DD petName.')),
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
    if (_messageController.text.isNotEmpty) {
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
          setState(() {
            _messages.add({
              'sender': 'ai',
              'text': aiResponse,
            });
          });
        } catch (e) {
          setState(() {
            _messages.add({
              'sender': 'ai',
              'text': 'Error: Unable to fetch response.',
            });
          });
        }
      }
    }
  }

  Future<String> _sendMessageToAI(String userMessage) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $_apiKey',
    };
    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "system", "content": "You are a helpful assistant specialized in pet care and solving pet-related problems. Please answer only questions related to pet care."},
        {"role": "user", "content": userMessage}
      ]
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to fetch AI response: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Chat with AI'),
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
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    padding: EdgeInsets.all(12.0),
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
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.send),
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
              MaterialPageRoute(builder: (context) => HomePage(currentLanguage: 'hu',)),
            );
          }
        },
        currentIndex: 1,
      ),
    );
  }
}
