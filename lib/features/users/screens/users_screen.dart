import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/wave_clipper.dart';
import '../../calls/screens/call_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final authService = AuthService();
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Online', 'My Program'];
  final int _currentNavIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final gradientColor1 = isDark 
        ? const Color(0xFF1A1A2E) 
        : const Color(0xFF4A148C);
    final gradientColor2 = isDark 
        ? const Color(0xFF16213E) 
        : const Color(0xFF7B1FA2);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [gradientColor1, gradientColor2],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Find Users',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name or program...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white70),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? const Color(0xFF2D2D2D) : Colors.grey[50],
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF4A148C),
                                        const Color(0xFF7B1FA2),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Users List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(AppConstants.usersCollection)
                      .where('uid', isNotEqualTo: authService.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: isDark ? Colors.white38 : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final users = snapshot.data!.docs;
                    final filteredUsers = users.where((doc) {
                      final user = doc.data() as Map<String, dynamic>;
                      final name = (user['displayName'] ?? '').toString().toLowerCase();
                      final program = (user['program'] ?? '').toString().toLowerCase();
                      final query = _searchController.text.toLowerCase();

                      // Filter by search query
                      if (query.isNotEmpty &&
                          !name.contains(query) &&
                          !program.contains(query)) {
                        return false;
                      }

                      // Filter by selected filter
                      if (_selectedFilter == 'Online' && user['isOnline'] != true) {
                        return false;
                      }
                      if (_selectedFilter == 'My Program' &&
                          user['program'] != authService.currentUser?.displayName) {
                        return false;
                      }

                      return true;
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Text(
                          'No users match your search',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 100, top: 8),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: isDark ? Colors.white12 : Colors.grey[300]),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index].data() as Map<String, dynamic>;
                        return _buildUserTile(user, isDark, context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Bottom Navigation - Always visible
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigation(gradientColor1, gradientColor2, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, bool isDark, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user['photoUrl'] != null
                  ? NetworkImage(user['photoUrl'])
                  : null,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
              child: user['photoUrl'] == null
                  ? Text(
                      (user['displayName'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            if (user['isOnline'] == true)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user['displayName'] ?? 'Unknown',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${user['program'] ?? 'N/A'} • Level ${user['level'] ?? 100}',
          style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.call, color: RegentColors.blue),
              iconSize: 20,
              onPressed: () => _startCall(user, isVideo: false),
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: RegentColors.blue),
              iconSize: 20,
              onPressed: () => _startCall(user, isVideo: true),
            ),
          ],
        ),
        onTap: () => _showUserProfile(user, context, isDark),
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

  void _showUserProfile(Map<String, dynamic> user, BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: user['photoUrl'] != null
                    ? NetworkImage(user['photoUrl'])
                    : null,
                child: user['photoUrl'] == null
                    ? Text(
                        (user['displayName'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user['displayName'] ?? 'Unknown',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                user['email'] ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileInfo('Program', user['program'] ?? 'N/A'),
            _buildProfileInfo('Level', 'Level ${user['level'] ?? 100}'),
            _buildProfileInfo('About', user['about'] ?? 'Hey there! I\'m using Regent Connect'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startCall(user, isVideo: false);
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RegentColors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startCall(user, isVideo: true);
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RegentColors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(Color color1, Color color2, bool isDark) {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 100),
            painter: WavePainter(
              color1: color1,
              color2: color2,
              isTop: false,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.chat_bubble_rounded, 'Chats', color1),
                    _buildNavItem(1, Icons.call_rounded, 'Calls', color1),
                    _buildNavItem(2, Icons.donut_large_rounded, 'Status', color1),
                    _buildNavItem(3, Icons.school_rounded, 'Academics', color1),
                    _buildNavItem(4, Icons.settings_rounded, 'Settings', color1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color color1) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, '/home');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
