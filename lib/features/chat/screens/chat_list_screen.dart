import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../../widgets/regent_ai_fab.dart';
import '../../calls/screens/call_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authService.currentUser?.uid;
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
        title: const Text("Regent Connect", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          Tooltip(
            message: 'Past Questions',
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/past-questions'),
              icon: const Icon(Icons.library_books, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: gradientColor2.withOpacity(0.3),
            height: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildChatsTab(currentUserId),
              _buildStatusTab(),
              _buildCallsTab(currentUserId),
            ],
          ),
          const RegentAICrystalFab(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          backgroundColor: RegentColors.green,
          heroTag: 'newChatFab',
          onPressed: () => _handleFabPress(),
          child: Icon(
            _getFabIcon(),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData _getFabIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.chat;
      case 1:
        return Icons.camera_alt;
      case 2:
        return Icons.add_call;
      default:
        return Icons.chat;
    }
  }

  void _handleFabPress() {
    switch (_tabController.index) {
      case 0:
        // Chats tab - show new chat options
        _showNewChatOptions();
        break;
      case 1:
        // Status tab - go to status screen
        Navigator.pushNamed(context, '/status');
        break;
      case 2:
        // Calls tab - show new call options
        _showNewCallOptions();
        break;
    }
  }

  void _showNewChatOptions() {
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
                'New Conversation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RegentColors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: RegentColors.green),
                ),
                title: const Text('New Chat'),
                subtitle: const Text('Start a one-on-one conversation'),
                onTap: () {
                  Navigator.pop(context);
                  // Already on chat list, users can tap on any user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tap on a user to start chatting')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add, color: Colors.blue),
                ),
                title: const Text('New Group'),
                subtitle: const Text('Create a study group'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-group');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign, color: Colors.orange),
                ),
                title: const Text('New Broadcast'),
                subtitle: const Text('Send to multiple contacts'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Broadcast feature coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewCallOptions() {
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
                'New Call',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RegentColors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: RegentColors.green),
                ),
                title: const Text('Voice Call'),
                subtitle: const Text('Start an audio call'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(0); // Go to chats to select user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a user to call from the chat list')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam, color: Colors.blue),
                ),
                title: const Text('Video Call'),
                subtitle: const Text('Start a video call'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(0); // Go to chats to select user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a user to video call from the chat list')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _ChatSearchDelegate(authService: authService),
    );
  }

  Widget _buildChatsTab(String? currentUserId) {
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
          padding: const EdgeInsets.only(bottom: 150), // Space for FABs
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
                    onPressed: () => _startCall(user, isVideo: false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: RegentColors.blue),
                    onPressed: () => _startCall(user, isVideo: true),
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

  Widget _buildStatusTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.donut_large, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Status Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Share what\'s on your mind', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/status'),
            icon: const Icon(Icons.add),
            label: const Text('View Statuses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RegentColors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab(String? currentUserId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.call, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No recent calls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Your call history will appear here', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select a user to start a call')),
              );
            },
            icon: const Icon(Icons.add_call),
            label: const Text('Start a Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RegentColors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _startCall(Map<String, dynamic> user, {required bool isVideo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          recipientId: user['uid'],
          recipientName: user['displayName'] ?? 'Unknown',
          recipientPhotoUrl: user['photoUrl'],
          isVideoCall: isVideo,
        ),
      ),
    );
  }
}

// Search Delegate for Chat
class _ChatSearchDelegate extends SearchDelegate {
  final AuthService authService;

  _ChatSearchDelegate({required this.authService});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Search for users', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('uid', isNotEqualTo: authService.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs.where((doc) {
          final user = doc.data() as Map<String, dynamic>;
          final name = (user['displayName'] ?? '').toString().toLowerCase();
          final program = (user['program'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) || program.contains(query.toLowerCase());
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Text('No results for "$query"'),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                child: Text(user['displayName']?[0]?.toUpperCase() ?? '?'),
              ),
              title: Text(user['displayName'] ?? 'Unknown'),
              subtitle: Text(user['program'] ?? ''),
              onTap: () {
                close(context, null);
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
