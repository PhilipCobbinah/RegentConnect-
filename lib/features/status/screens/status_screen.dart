import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../services/status_service.dart';
import 'view_status_screen.dart';
import 'create_status_screen.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final StatusService _statusService = StatusService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegentColors.dmBackground,
      appBar: AppBar(
        backgroundColor: RegentColors.dmSurface,
        title: const Text('Status', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Status section
          _buildMyStatusSection(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Recent updates',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Others' statuses
          Expanded(child: _buildOthersStatuses()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'text_status',
            backgroundColor: RegentColors.dmCard,
            onPressed: () => _createTextStatus(),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'media_status',
            backgroundColor: RegentColors.violet,
            onPressed: () => _showMediaOptions(),
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _statusService.getMyStatuses(),
      builder: (context, snapshot) {
        final hasStatus = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: hasStatus ? RegentColors.violet : RegentColors.dmCard,
                child: hasStatus
                    ? _buildStatusPreview(snapshot.data!.docs.first.data() as Map<String, dynamic>)
                    : const Icon(Icons.person, color: Colors.white54, size: 30),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: RegentColors.violet,
                    shape: BoxShape.circle,
                    border: Border.all(color: RegentColors.dmBackground, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          title: const Text('My Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(
            hasStatus ? 'Tap to view' : 'Tap to add status update',
            style: const TextStyle(color: Colors.white54),
          ),
          onTap: () {
            if (hasStatus) {
              _viewMyStatuses(snapshot.data!.docs);
            } else {
              _showMediaOptions();
            }
          },
        );
      },
    );
  }

  Widget _buildStatusPreview(Map<String, dynamic> status) {
    final type = status['type'];
    if (type == 'image' && status['mediaUrl'] != null) {
      return ClipOval(
        child: Image.network(
          status['mediaUrl'],
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    } else if (type == 'video') {
      return const Icon(Icons.play_circle, color: Colors.white, size: 30);
    } else {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Color(int.parse(status['backgroundColor']?.replaceFirst('#', '0xFF') ?? '0xFF7C4DFF')),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.text_fields, color: Colors.white, size: 24),
        ),
      );
    }
  }

  Widget _buildOthersStatuses() {
    return StreamBuilder<QuerySnapshot>(
      stream: _statusService.getAllStatuses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: RegentColors.violet));
        }

        // Group statuses by user
        final Map<String, List<QueryDocumentSnapshot>> groupedStatuses = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final odbc = data['userId'] as String;
          
          // Skip current user's statuses
          if (userId == _statusService.currentUserId) continue;
          
          if (!groupedStatuses.containsKey(userId)) {
            groupedStatuses[userId] = [];
          }
          groupedStatuses[userId]!.add(doc);
        }

        if (groupedStatuses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_outlined, size: 60, color: Colors.white24),
                SizedBox(height: 16),
                Text('No status updates', style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: groupedStatuses.length,
          itemBuilder: (context, index) {
            final odbc = groupedStatuses.keys.elementAt(index);
            final statuses = groupedStatuses[userId]!;
            final latestStatus = statuses.first.data() as Map<String, dynamic>;
            final hasViewed = _hasViewedAllStatuses(statuses);

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasViewed ? Colors.white38 : RegentColors.violet,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: RegentColors.dmCard,
                  backgroundImage: latestStatus['userPhoto'] != null
                      ? NetworkImage(latestStatus['userPhoto'])
                      : null,
                  child: latestStatus['userPhoto'] == null
                      ? Text(
                          (latestStatus['userName'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              title: Text(
                latestStatus['userName'] ?? 'Unknown',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _getTimeAgo(latestStatus['createdAt']),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: statuses.length > 1
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: RegentColors.violet.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${statuses.length}',
                        style: const TextStyle(color: RegentColors.violet, fontSize: 12),
                      ),
                    )
                  : null,
              onTap: () => _viewStatuses(statuses),
            );
          },
        );
      },
    );
  }

  bool _hasViewedAllStatuses(List<QueryDocumentSnapshot> statuses) {
    for (var doc in statuses) {
      final data = doc.data() as Map<String, dynamic>;
      final views = List<Map<String, dynamic>>.from(data['views'] ?? []);
      final hasViewed = views.any((view) => view['userId'] == _statusService.currentUserId);
      if (!hasViewed) return false;
    }
    return true;
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _viewMyStatuses(List<QueryDocumentSnapshot> docs) {
    final statuses = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewStatusScreen(
          statuses: statuses,
          isOwner: true,
        ),
      ),
    );
  }

  void _viewStatuses(List<QueryDocumentSnapshot> docs) {
    final statuses = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewStatusScreen(
          statuses: statuses,
          isOwner: false,
        ),
      ),
    );
  }

  void _createTextStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStatusScreen(type: 'text'),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: RegentColors.dmSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Status',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _mediaOption(Icons.text_fields, 'Text', () {
                  Navigator.pop(context);
                  _createTextStatus();
                }),
                _mediaOption(Icons.photo, 'Gallery', () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _createMediaStatus(File(image.path), 'image');
                  }
                }),
                _mediaOption(Icons.camera_alt, 'Camera', () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    _createMediaStatus(File(image.path), 'image');
                  }
                }),
                _mediaOption(Icons.videocam, 'Video', () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final video = await picker.pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    _createMediaStatus(File(video.path), 'video');
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: RegentColors.violet,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  void _createMediaStatus(File file, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStatusScreen(type: type, mediaFile: file),
      ),
    );
  }
}
