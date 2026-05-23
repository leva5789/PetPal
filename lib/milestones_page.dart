import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_theme.dart';
import 'app_toast.dart';
import 'footer.dart';
import 'widgets/premium_widgets.dart';
import 'new_pet_form_page.dart';

class MilestonesPage extends StatefulWidget {
  const MilestonesPage({super.key});

  @override
  State<MilestonesPage> createState() => _MilestonesPageState();
}

class _MilestonesPageState extends State<MilestonesPage> {
  String? _selectedPetId;
  List<QueryDocumentSnapshot> _userPets = [];
  bool _isLoadingPets = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  static const String _storageProxyUrl =
      'https://getstorageimage-md6ydt4via-uc.a.run.app';

  @override
  void initState() {
    super.initState();
    _fetchUserPets();
  }

  Future<void> _fetchUserPets() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final householdId = userDoc.exists
          ? (userDoc.data()?['householdId'] as String?) ?? user.uid
          : user.uid;

      final snapshot = await _firestore
          .collection('pets')
          .where('householdId', isEqualTo: householdId)
          .get();

      if (mounted) {
        setState(() {
          _userPets = snapshot.docs;
          if (_userPets.isNotEmpty) {
            _selectedPetId = _userPets.first.id;
          }
          _isLoadingPets = false;
        });
      }
    } catch (e) {
      print('Error fetching pets: $e');
      if (mounted) setState(() => _isLoadingPets = false);
    }
  }

  void _showAddMilestoneDialog() {
    if (_selectedPetId == null) {
      AppToast.warning(context, 'Please add a pet first!');
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedIcon = '🏆';
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isUploading = false;

    final List<String> icons = [
      '🏆',
      '🏥',
      '🏠',
      '🎂',
      '🎾',
      '🎓',
      '✈️',
      '📸',
      '🦴',
      '🚶'
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Memory',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.darkText,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: isDark ? Colors.grey : Colors.black54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PremiumTextField(
                        controller: titleController,
                        label: 'Title',
                        hint: 'e.g., Adopted!',
                        prefixIcon: Icons.title,
                      ),
                      const SizedBox(height: 16),
                      PremiumTextField(
                        controller: descriptionController,
                        label: 'Description (optional)',
                        hint: 'Tell us more about this day...',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat.yMMMd().format(selectedDate),
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white : AppTheme.darkText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          try {
                            final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setDialogState(() {
                                selectedImageBytes = bytes;
                                selectedImageName = image.name;
                              });
                            }
                          } catch (e) {
                            print("Error picking image: $e");
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDark ? Colors.white10 : Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: selectedImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.memory(selectedImageBytes!,
                                      fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_rounded,
                                        size: 40,
                                        color: AppTheme.mint.withOpacity(0.7)),
                                    const SizedBox(height: 8),
                                    Text('Add Photo',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        )),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Choose Icon',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          )),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: icons.map((icon) {
                          final isSelected = selectedIcon == icon;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedIcon = icon),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.mint.withOpacity(0.2)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.transparent),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.mint
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      if (isUploading)
                        Column(
                          children: [
                            const CircularProgressIndicator(
                                color: AppTheme.mint),
                            const SizedBox(height: 16),
                            Text('Saving memory...',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        )
                      else
                        AnimatedPressButton(
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) return;

                            setDialogState(() => isUploading = true);

                            try {
                              String? imageUrl;
                              String? storagePath;

                              if (selectedImageBytes != null) {
                                final String fileName =
                                    '${DateTime.now().millisecondsSinceEpoch}_${selectedImageName ?? "image.jpg"}';
                                storagePath =
                                    'milestone_images/$_selectedPetId/$fileName';
                                final ref = _storage.ref().child(storagePath);

                                await ref.putData(selectedImageBytes!);
                                imageUrl = await ref.getDownloadURL();
                              }

                              await _firestore
                                  .collection('pets')
                                  .doc(_selectedPetId)
                                  .collection('milestones')
                                  .add({
                                'title': titleController.text.trim(),
                                'description':
                                    descriptionController.text.trim(),
                                'date': Timestamp.fromDate(selectedDate),
                                'icon': selectedIcon,
                                'imageUrl': imageUrl,
                                'storagePath': storagePath,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              print("Error uploading: $e");
                              setDialogState(() => isUploading = false);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppTheme.mintGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.mint.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Text('Save Memory',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteMilestone(String milestoneId, String? imageUrl) {
    showDialog(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
            title: Text('Delete Memory?',
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.darkText)),
            content: Text('This cannot be undone.',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      try {
                        await _storage.refFromURL(imageUrl).delete();
                      } catch (e) {}
                    }
                    await _firestore
                        .collection('pets')
                        .doc(_selectedPetId)
                        .collection('milestones')
                        .doc(milestoneId)
                        .delete();
                    if (mounted) Navigator.pop(context);
                  } catch (e) {}
                },
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMilestoneDialog,
        label: const Text('Add Memory'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.mint,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.mint.withOpacity(isDark ? 0.05 : 0.1),
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
                _buildPetSelector(isDark),
                Expanded(
                  child: _selectedPetId == null
                      ? _buildEmptyStateIfNeeded(isDark)
                      : StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('pets')
                              .doc(_selectedPetId)
                              .collection('milestones')
                              .orderBy('date', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: AppTheme.mint));
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return _buildEmptyStateIfNeeded(isDark);
                            }

                            final milestones = snapshot.data!.docs;

                            return ListView.builder(
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, bottom: 80, top: 10),
                              itemCount: milestones.length,
                              itemBuilder: (context, index) {
                                final data = milestones[index].data()
                                    as Map<String, dynamic>;
                                return _buildMilestoneCard(
                                    milestones[index].id, data, index, isDark);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
            currentIndex: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Milestones',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.darkText,
            ),
          ),
          const SizedBox(width: 8),
          const Text('🏆', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildPetSelector(bool isDark) {
    if (_userPets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPetId,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white : AppTheme.darkText),
          items: _userPets.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(data['profilePictureUrl'] ??
                            'https://via.placeholder.com/150'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    data['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.darkText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedPetId = val);
          },
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(
      String id, Map<String, dynamic> data, int index, bool isDark) {
    final date = (data['date'] as Timestamp).toDate();
    final imageUrl = data['imageUrl'] as String?;
    final storagePath = data['storagePath'] as String?;

    return AnimatedCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {},
      child: InkWell(
        onLongPress: () => _deleteMilestone(id, imageUrl),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.mint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat.d().format(date),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.mint,
                          ),
                        ),
                        Text(
                          DateFormat.MMM().format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(data['icon'] ?? '🏆',
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['title'] ?? 'Memory',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : AppTheme.darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (data['description'] != null &&
                            data['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                child: AppNetworkImage(
                                  imageUrl: imageUrl,
                                  storagePath: storagePath,
                                  proxyUrl: _storageProxyUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 20,
                              right: 20,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 30),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: AppNetworkImage(
                        imageUrl: imageUrl,
                        storagePath: storagePath,
                        proxyUrl: _storageProxyUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: (100 * index).ms)
          .slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildEmptyStateIfNeeded(bool isDark) {
    if (_userPets.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.pets_rounded,
          title: 'No Pets Found',
          subtitle: 'Add a pet to start tracking their special moments!',
          actionLabel: 'Add New Pet',
          onAction: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NewPetFormPage(currentLanguage: 'en')),
            );
            _fetchUserPets();
          },
        ),
      );
    }
    return Center(
      child: EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No Memories Yet',
        subtitle: 'Add your first milestone to celebrate your pet\'s journey!',
        actionLabel: 'Add Memory',
        onAction: _showAddMilestoneDialog,
      ),
    );
  }
}

class AppNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final String? storagePath;
  final String proxyUrl;
  final BoxFit fit;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    required this.storagePath,
    required this.proxyUrl,
    this.fit = BoxFit.contain,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  String? _currentUrl;
  bool _useProxy = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setInitialUrl();
  }

  @override
  void didUpdateWidget(AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.storagePath != widget.storagePath) {
      _hasError = false;
      _setInitialUrl();
    }
  }

  void _setInitialUrl() {
    if (kIsWeb && widget.storagePath != null && widget.proxyUrl.isNotEmpty) {
      _currentUrl =
          '${widget.proxyUrl}?path=${Uri.encodeComponent(widget.storagePath!)}';
      _useProxy = true;
    } else {
      _currentUrl = widget.imageUrl;
      _useProxy = false;
    }
  }

  void _handleError() {
    if (_hasError) return;

    if (_useProxy && widget.imageUrl != null) {
      print(
          "Proxy failed for ${widget.storagePath}, falling back to original URL: ${widget.imageUrl}");
      setState(() {
        _useProxy = false;
        _currentUrl = widget.imageUrl;
      });
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _currentUrl == null || _currentUrl!.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
          SizedBox(height: 4),
          Text("Image unavailable",
              style: TextStyle(color: Colors.grey, fontSize: 10))
        ])),
      );
    }

    return Image.network(
      _currentUrl!,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: AppTheme.mint,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleError();
        });
        return Container(color: Colors.grey[100]);
      },
    );
  }
}
