import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _editUserDialog(
      String userId,
      String currentUsername,
      String currentEmail,
      bool isPremium,
      ) async {
    final usernameController = TextEditingController(text: currentUsername);
    final emailController = TextEditingController(text: currentEmail);
    bool premiumValue = isPremium;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit user'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Premium'),
                  const SizedBox(width: 8),
                  StatefulBuilder(
                    builder: (context, setInnerState) {
                      return Switch(
                        value: premiumValue,
                        onChanged: (val) {
                          setInnerState(() {
                            premiumValue = val;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: This changes Firestore fields.\n'
                    'Updating Firebase Auth email / deleting auth accounts\n'
                    'should be done via a secure Cloud Function.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                final newEmail = emailController.text.trim();

                await _firestore.collection('users').doc(userId).update({
                  'username': newUsername,
                  'email': newEmail,
                  'isPremium': premiumValue,
                });

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserAndPets(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: const Text(
          'Are you sure you want to delete this user and all their pets?\n'
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;


    final petsSnapshot = await _firestore
        .collection('pets')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in petsSnapshot.docs) {
      await doc.reference.delete();
    }


    await _firestore.collection('users').doc(userId).delete();


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User and pets deleted from Firestore.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return const Center(child: Text('Error loading users.'));
          }

          final users = userSnapshot.data?.docs ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;

              final userId = doc.id;
              final fullName = data['fullName']?.toString() ?? '';
              final username = data['username']?.toString() ?? '';
              final email = data['email']?.toString() ?? '';
              final isPremium = data['isPremium'] as bool? ?? false;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(fullName.isNotEmpty ? fullName : '(no name)'),
                  subtitle: Text(
                    'Username: $username\nEmail: $email',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Premium'),
                      Switch(
                        value: isPremium,
                        onChanged: (val) async {
                          await _firestore
                              .collection('users')
                              .doc(userId)
                              .update({'isPremium': val});
                        },
                      ),
                    ],
                  ),
                  children: [
                    // PETA LISTA
                    FutureBuilder<QuerySnapshot>(
                      future: _firestore
                          .collection('pets')
                          .where('userId', isEqualTo: userId)
                          .get(),
                      builder: (context, petsSnapshot) {
                        if (petsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: LinearProgressIndicator(),
                          );
                        }
                        if (petsSnapshot.hasError) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Error loading pets.'),
                          );
                        }

                        final pets = petsSnapshot.data?.docs ?? [];
                        if (pets.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No pets for this user.'),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'Pets:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...pets.map((petDoc) {
                              final petData =
                              petDoc.data() as Map<String, dynamic>;
                              final petName =
                                  petData['name']?.toString() ?? 'Unnamed pet';
                              final petBreed =
                                  petData['breed']?.toString() ?? '';

                              return ListTile(
                                title: Text(petName),
                                subtitle: Text(
                                  petBreed.isNotEmpty ? petBreed : 'No breed',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await petDoc.reference.delete();
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),

                    const Divider(),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () {
                            _editUserDialog(
                              userId,
                              username,
                              email,
                              isPremium,
                            );
                          },
                          child: const Text('Edit user'),
                        ),
                        TextButton(
                          onPressed: () => _deleteUserAndPets(userId),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete user'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
