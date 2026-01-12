import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../../models/status_model.dart';
import '../../../services/status_service.dart';
import '../../../services/auth_service.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final statusService = StatusService();
  final authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final gradientColor1 = isDark 
        ? const Color(0xFF1A1A2E) 
        : const Color(0xFF4A148C);
    final gradientColor2 = isDark 
        ? const Color(0xFF16213E) 
        : const Color(0xFF7B1FA2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: gradientColor1,
        elevation: 0,
        title: const Text('Status Updates', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<StatusModel>>(
        stream: statusService.getActiveStatuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allStatuses = snapshot.data ?? [];
          
          // Group statuses by user
          final Map<String, List<StatusModel>> groupedStatuses = {};
          for (var status in allStatuses) {
            groupedStatuses.putIfAbsent(status.postedBy, () => []).add(status);
          }

          // Separate my statuses
          final myStatuses = groupedStatuses[currentUser?.uid] ?? [];
          final otherStatuses = Map<String, List<StatusModel>>.from(groupedStatuses)
            ..remove(currentUser?.uid);

          return ListView(
            children: [
              // My Status Section
              ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: myStatuses.isNotEmpty ? RegentColors.green : Colors.grey[300],
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          currentUser?.displayName?[0].toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (myStatuses.isEmpty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: RegentColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
                title: const Text('My Status', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  myStatuses.isEmpty 
                      ? 'Tap to add status update' 
                      : '${myStatuses.length} status update(s)',
                ),
                onTap: () {
                  if (myStatuses.isEmpty) {
                    _showAddStatusDialog(context);
                  } else {
                    _viewStatuses(context, myStatuses, isMyStatus: true);
                  }
                },
              ),
              const Divider(),
              
              // Recent Updates Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Recent Updates',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Other Users' Statuses
              if (otherStatuses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No status updates', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ...otherStatuses.entries.map((entry) {
                  final userStatuses = entry.value;
                  final latestStatus = userStatuses.first;
                  final hasViewed = userStatuses.every(
                    (s) => s.viewedBy.contains(currentUser?.uid)
                  );

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasViewed ? Colors.grey : RegentColors.green,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: latestStatus.posterPhotoUrl != null
                            ? NetworkImage(latestStatus.posterPhotoUrl!)
                            : null,
                        child: latestStatus.posterPhotoUrl == null
                            ? Text(latestStatus.posterName[0].toUpperCase())
                            : null,
                      ),
                    ),
                    title: Text(
                      latestStatus.posterName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_getTimeAgo(latestStatus.createdAt)),
                    onTap: () => _viewStatuses(context, userStatuses),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: RegentColors.green,
        onPressed: () => _showAddStatusDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddStatusDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusOption(
                    icon: Icons.text_fields,
                    label: 'Text',
                    color: RegentColors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _showTextStatusDialog(context);
                    },
                  ),
                  _buildStatusOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildStatusOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showTextStatusDialog(BuildContext context) {
    final textController = TextEditingController();
    String selectedColor = '#1565C0';
    
    final colors = [
      '#1565C0', // Blue
      '#2E7D32', // Green
      '#C62828', // Red
      '#6A1B9A', // Purple
      '#E65100', // Orange
      '#00838F', // Teal
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Text Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Background Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((color) {
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
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
                if (textController.text.trim().isEmpty) return;
                Navigator.pop(context);
                await _postTextStatus(textController.text.trim(), selectedColor);
              },
              style: ElevatedButton.styleFrom(backgroundColor: RegentColors.green),
              child: const Text('Post', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _postTextStatus(String content, String backgroundColor) async {
    final user = authService.currentUser;
    if (user == null) return;

    final result = await statusService.postTextStatus(
      odId: user.uid,
      content: content,
      posterName: user.displayName ?? 'Unknown',
      posterPhotoUrl: user.photoURL,
      backgroundColor: backgroundColor,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result != null ? 'Status posted!' : 'Failed to post status'),
          backgroundColor: result != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        await _postImageStatus(bytes, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        await _postImageStatus(bytes, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _postImageStatus(Uint8List bytes, String fileName) async {
    final user = authService.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await statusService.postImageStatus(
      odId: user.uid,
      posterName: user.displayName ?? 'Unknown',
      posterPhotoUrl: user.photoURL,
      imageBytes: bytes,
      fileName: fileName,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result != null ? 'Status posted!' : 'Failed to post status'),
          backgroundColor: result != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _viewStatuses(BuildContext context, List<StatusModel> statuses, {bool isMyStatus = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerScreen(
          statuses: statuses,
          isMyStatus: isMyStatus,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// Status Viewer Screen
class StatusViewerScreen extends StatefulWidget {
  final List<StatusModel> statuses;
  final bool isMyStatus;

  const StatusViewerScreen({
    super.key,
    required this.statuses,
    this.isMyStatus = false,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  int currentIndex = 0;
  final statusService = StatusService();
  final authService = AuthService();
  final _messageController = TextEditingController();
  bool _showInputField = false;

  @override
  void initState() {
    super.initState();
    _markAsViewed();
  }

  void _markAsViewed() async {
    final userId = authService.currentUser?.uid;
    if (userId == null || widget.isMyStatus) return;

    for (var status in widget.statuses) {
      if (!status.viewedBy.contains(userId)) {
        await statusService.markAsViewed(status.id, userId);
      }
    }
  }

  void _nextStatus() {
    if (currentIndex < widget.statuses.length - 1) {
      setState(() => currentIndex++);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStatus() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.statuses[currentIndex];
    final backgroundColor = status.type == 'text' && status.backgroundColor != null
        ? Color(int.parse(status.backgroundColor!.replaceFirst('#', '0xFF')))
        : Colors.black;
    final isLiked = status.likedBy.contains(authService.currentUser?.uid);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _previousStatus();
          } else {
            _nextStatus();
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Progress indicators
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: List.generate(widget.statuses.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= currentIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Header
              Positioned(
                top: 20,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: status.posterPhotoUrl != null
                          ? NetworkImage(status.posterPhotoUrl!)
                          : null,
                      child: status.posterPhotoUrl == null
                          ? Text(status.posterName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.posterName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getTimeAgo(status.createdAt),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isMyStatus)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await statusService.deleteStatus(
                              status.id,
                              status.type == 'image' ? status.content : null,
                            );
                            if (mounted) {
                              if (widget.statuses.length == 1) {
                                Navigator.pop(context);
                              } else {
                                setState(() {
                                  widget.statuses.removeAt(currentIndex);
                                  if (currentIndex >= widget.statuses.length) {
                                    currentIndex = widget.statuses.length - 1;
                                  }
                                });
                              }
                            }
                          } else if (value == 'views') {
                            _showViewers(status);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'views',
                            child: Row(
                              children: [
                                const Icon(Icons.visibility),
                                const SizedBox(width: 8),
                                Text('${status.viewedBy.length} views'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Content
              Center(
                child: status.type == 'text'
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          status.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Image.network(
                        status.content,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        },
                      ),
              ),

              // Bottom Action Bar
              if (!widget.isMyStatus)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Like, Sticker, Audio buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Like Button
                            GestureDetector(
                              onTap: () async {
                                await statusService.toggleLikeStatus(
                                  status.id,
                                  authService.currentUser!.uid,
                                );
                                setState(() {});
                              },
                              child: Column(
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.white,
                                    size: 28,
                                  ),
                                  Text(
                                    '${status.likedBy.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Sticker Button
                            GestureDetector(
                              onTap: () => _showStickerPicker(),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.emoji_emotions_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  Text(
                                    'Sticker',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Audio Note Button
                            GestureDetector(
                              onTap: () => _recordAudioNote(),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  Text(
                                    'Audio',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Message Button
                            GestureDetector(
                              onTap: () => setState(() => _showInputField = true),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.message_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  Text(
                                    'Message',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Message Input Field
                        if (_showInputField)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    style: const TextStyle(color: Colors.white),
                                    onSubmitted: (_) => _sendMessage(status),
                                    decoration: InputDecoration(
                                      hintText: 'Send message...',
                                      hintStyle: const TextStyle(color: Colors.white60),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(color: Colors.white30),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _sendMessage(status),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStickerPicker() {
    final stickers = ['😀', '😂', '❤️', '🔥', '👍', '🎉', '😍', '🤔'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black87,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          ),
          itemCount: stickers.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                _messageController.text = stickers[index];
                Navigator.pop(context);
                setState(() => _showInputField = true);
              },
              child: Text(
                stickers[index],
                style: const TextStyle(fontSize: 40),
              ),
            );
          },
        ),
      ),
    );
  }

  void _recordAudioNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio note feature coming soon!'),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement audio recording using record package
  }

  Future<void> _sendMessage(StatusModel status) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      // Send message to status poster
      final currentUser = authService.currentUser;
      final chatId = _generateChatId(currentUser!.uid, status.postedBy);
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set({
            'senderId': currentUser.uid,
            'senderName': currentUser.displayName,
            'senderPhotoUrl': currentUser.photoURL,
            'content': message,
            'type': 'text',
            'timestamp': DateTime.now(),
            'isRead': false,
          });

      _messageController.clear();
      setState(() => _showInputField = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _generateChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 ? '$userId1-$userId2' : '$userId2-$userId1';
  }

  void _showViewers(StatusModel status) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Viewed by ${status.viewedBy.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (status.viewedBy.isEmpty)
              const Text('No views yet')
            else
              const Text('Viewers list will show here'),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
