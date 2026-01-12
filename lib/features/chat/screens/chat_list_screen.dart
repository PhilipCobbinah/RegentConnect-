import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import '../../../services/chat_service.dart';
import '../../../services/status_service.dart';
import 'dm_screen.dart';
import '../../status/screens/view_status_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  final _statusService = StatusService();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegentColors.dmBackground,
      appBar: AppBar(
        backgroundColor: RegentColors.dmSurface,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              )
            : Row(
                children: [
                  const Text('Messages', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  // Unread count badge
                  StreamBuilder<int>(
                    stream: _chatService.getTotalUnreadCount(),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      if (unreadCount == 0) return const SizedBox.shrink();
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RegentColors.violet,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
        actions: [
          // Unread filter button
          StreamBuilder<int>(
            stream: _chatService.getTotalUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mark_chat_unread, color: Colors.white),
                    onPressed: () => _showUnreadChats(),
                    tooltip: 'Unread messages',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Chat rooms are already ordered by lastMessageTime descending in the service
        stream: _chatService.getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: RegentColors.violet));
          }

          final chatRooms = snapshot.data!.docs;

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: RegentColors.violet.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a chat with someone!',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final data = chatRooms[index].data() as Map<String, dynamic>;
              final participants = List<String>.from(data['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != _chatService.currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox();

              return FutureBuilder<Map<String, dynamic>?>(
                future: _chatService.getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;
                  final userName = userData?['fullName'] ?? userData?['email'] ?? 'Unknown';
                  final userPhoto = userData?['photoUrl'];
                  final lastMessage = data['lastMessage'] ?? '';
                  final lastTime = data['lastMessageTime'] as Timestamp?;
                  
                  // Format time based on how recent
                  String timeStr = '';
                  if (lastTime != null) {
                    final now = DateTime.now();
                    final messageDate = lastTime.toDate();
                    final today = DateTime(now.year, now.month, now.day);
                    final msgDay = DateTime(messageDate.year, messageDate.month, messageDate.day);
                    
                    if (msgDay == today) {
                      // Today - show time
                      timeStr = '${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
                    } else if (msgDay == today.subtract(const Duration(days: 1))) {
                      // Yesterday
                      timeStr = 'Yesterday';
                    } else if (now.difference(messageDate).inDays < 7) {
                      // Within a week - show day name
                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      timeStr = days[messageDate.weekday - 1];
                    } else {
                      // Older - show date
                      timeStr = '${messageDate.day}/${messageDate.month}/${messageDate.year}';
                    }
                  }

                  // Check if there's typing
                  return StreamBuilder<DocumentSnapshot>(
                    stream: _chatService.getTypingStatus(otherUserId),
                    builder: (context, typingSnapshot) {
                      String subtitleText = lastMessage;
                      bool isTyping = false;
                      
                      if (typingSnapshot.hasData && typingSnapshot.data!.exists) {
                        final typingData = typingSnapshot.data!.data() as Map<String, dynamic>?;
                        final typing = typingData?['typing'] as Map<String, dynamic>?;
                        if (typing?[otherUserId] != null) {
                          subtitleText = 'typing...';
                          isTyping = true;
                        }
                      }

                      return _ChatListTile(
                        odbc: otherUserId,
                        userName: userName,
                        userPhoto: userPhoto,
                        lastMessage: subtitleText,
                        timeStr: timeStr,
                        isTyping: isTyping,
                        statusService: _statusService,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DMScreen(
                                recipientId: otherUserId,
                                recipientName: userName,
                                recipientPhoto: userPhoto,
                              ),
                            ),
                          );
                        },
                        onStatusTap: (statuses) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewStatusScreen(
                                statuses: statuses,
                                isOwner: false,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: RegentColors.violet,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () => _showUsersList(context),
      ),
    );
  }

  void _showUsersList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RegentColors.dmSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Start a conversation',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: RegentColors.violet));
                  }

                  final users = snapshot.data!.docs.where((doc) => doc.id != _chatService.currentUserId).toList();

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final odbc = users[index].id;
                      final userName = userData['fullName'] ?? userData['email'] ?? 'Unknown';
                      final userPhoto = userData['photoUrl'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: RegentColors.violet,
                          backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
                          child: userPhoto == null
                              ? Text(userName[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                              : null,
                        ),
                        title: Text(userName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(userData['email'] ?? '', style: const TextStyle(color: Colors.white54)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DMScreen(
                                recipientId: userId,
                                recipientName: userName,
                                recipientPhoto: userPhoto,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnreadChats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: RegentColors.dmSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.mark_chat_unread, color: RegentColors.violet),
                  const SizedBox(width: 12),
                  const Text(
                    'Unread Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Mark all as read
                      Navigator.pop(context);
                      _markAllAsRead();
                    },
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            const Divider(color: RegentColors.dmCard, height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getChatRooms(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: RegentColors.violet),
                    );
                  }

                  final chatRooms = snapshot.data!.docs;

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: chatRooms.length,
                    itemBuilder: (context, index) {
                      final data = chatRooms[index].data() as Map<String, dynamic>;
                      final participants = List<String>.from(data['participants'] ?? []);
                      final otherUserId = participants.firstWhere(
                        (id) => id != _chatService.currentUserId,
                        orElse: () => '',
                      );

                      if (otherUserId.isEmpty) return const SizedBox();

                      return StreamBuilder<int>(
                        stream: _chatService.getUnreadCountForChat(otherUserId),
                        builder: (context, unreadSnapshot) {
                          final unreadCount = unreadSnapshot.data ?? 0;
                          if (unreadCount == 0) return const SizedBox.shrink();

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _chatService.getUserData(otherUserId),
                            builder: (context, userSnapshot) {
                              final userData = userSnapshot.data;
                              final userName = userData?['fullName'] ?? 
                                  userData?['email'] ?? 'Unknown';
                              final userPhoto = userData?['photoUrl'];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: RegentColors.violet,
                                  backgroundImage: userPhoto != null 
                                      ? NetworkImage(userPhoto) 
                                      : null,
                                  child: userPhoto == null
                                      ? Text(
                                          userName[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '$unreadCount unread message${unreadCount > 1 ? 's' : ''}',
                                  style: const TextStyle(color: RegentColors.lightViolet),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: RegentColors.violet,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DMScreen(
                                        recipientId: otherUserId,
                                        recipientName: userName,
                                        recipientPhoto: userPhoto,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    // This would mark all messages as read
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All messages marked as read'),
        backgroundColor: RegentColors.violet,
      ),
    );
  }
}

// Separate widget to handle status checking for each chat tile
class _ChatListTile extends StatelessWidget {
  final String odbc;
  final String userName;
  final String? userPhoto;
  final String lastMessage;
  final String timeStr;
  final bool isTyping;
  final StatusService statusService;
  final VoidCallback onTap;
  final Function(List<Map<String, dynamic>>) onStatusTap;

  const _ChatListTile({
    required this.odbc,
    required this.userName,
    required this.userPhoto,
    required this.lastMessage,
    required this.timeStr,
    this.isTyping = false,
    required this.statusService,
    required this.onTap,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('statuses')
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .snapshots(),
      builder: (context, statusSnapshot) {
        final hasStatus = statusSnapshot.hasData && statusSnapshot.data!.docs.isNotEmpty;
        final statuses = hasStatus
            ? statusSnapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
            : <Map<String, dynamic>>[];

        bool hasUnviewedStatus = false;
        if (hasStatus) {
          for (var status in statuses) {
            final views = List<Map<String, dynamic>>.from(status['views'] ?? []);
            final hasViewed = views.any((view) => view['userId'] == statusService.currentUserId);
            if (!hasViewed) {
              hasUnviewedStatus = true;
              break;
            }
          }
        }

        return StreamBuilder<int>(
          stream: chatService.getUnreadCountForChat(userId),
          builder: (context, unreadSnapshot) {
            final unreadCount = unreadSnapshot.data ?? 0;

            return ListTile(
              leading: GestureDetector(
                onTap: hasStatus ? () => onStatusTap(statuses) : null,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: hasStatus
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: hasUnviewedStatus
                                ? [RegentColors.violet, RegentColors.darkViolet, RegentColors.lightViolet]
                                : [Colors.grey, Colors.grey.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        )
                      : null,
                  child: Container(
                    padding: hasStatus ? const EdgeInsets.all(2) : EdgeInsets.zero,
                    decoration: hasStatus
                        ? const BoxDecoration(
                            shape: BoxShape.circle,
                            color: RegentColors.dmBackground,
                          )
                        : null,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: RegentColors.violet,
                      backgroundImage: userPhoto != null ? NetworkImage(userPhoto!) : null,
                      child: userPhoto == null
                          ? Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              title: Text(
                userName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                lastMessage,
                style: TextStyle(
                  color: isTyping ? RegentColors.lightViolet : Colors.white54,
                  fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: unreadCount > 0 ? RegentColors.violet : Colors.white54,
                      fontSize: 12,
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: RegentColors.violet,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (hasStatus && hasUnviewedStatus)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: RegentColors.violet,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}
