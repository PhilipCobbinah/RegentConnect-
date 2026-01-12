import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';
import '../../../core/theme.dart';

class ChatListTab extends StatefulWidget {
  final String filter;

  const ChatListTab({super.key, required this.filter});

  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  final authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = authService.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('uid', isNotEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No users found'),
                SizedBox(height: 8),
                Text('Invite your classmates to join!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 150),
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['photoUrl'] != null
                    ? NetworkImage(user['photoUrl'])
                    : null,
                child: user['photoUrl'] == null
                    ? Text(user['displayName']?[0]?.toUpperCase() ?? '?')
                    : null,
              ),
              title: Text(
                user['displayName'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user['program'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user['isOnline'] == true)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.circle, color: Colors.green, size: 12),
                    ),
                  IconButton(
                    icon: const Icon(Icons.call, color: RegentColors.blue),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: RegentColors.blue),
                    onPressed: () {},
                  ),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'userId': user['uid'],
                    'userName': user['displayName'],
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
