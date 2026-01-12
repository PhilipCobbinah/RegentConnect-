import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/status_service.dart';
import '../../../models/status_model.dart';
import 'status_screen.dart';

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final authService = AuthService();
    final statusService = StatusService();
    final currentUser = authService.currentUser;

    return StreamBuilder<List<StatusModel>>(
      stream: statusService.getActiveStatuses(),
      builder: (context, snapshot) {
        final allStatuses = snapshot.data ?? [];
        
        // Group statuses by user
        final Map<String, List<StatusModel>> groupedStatuses = {};
        for (var status in allStatuses) {
          groupedStatuses.putIfAbsent(status.postedBy, () => []).add(status);
        }

        final myStatuses = groupedStatuses[currentUser?.uid] ?? [];
        final otherStatuses = Map<String, List<StatusModel>>.from(groupedStatuses)
          ..remove(currentUser?.uid);

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // My Status
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: myStatuses.isNotEmpty ? RegentColors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
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
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
              title: Text(
                'My Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                myStatuses.isEmpty ? 'Tap to add status' : '${myStatuses.length} update(s)',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatusScreen()),
                );
              },
            ),
            
            Divider(color: isDark ? Colors.white12 : Colors.grey[300]),
            
            // Recent Updates Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Recent Updates',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            // Other Users' Statuses
            if (otherStatuses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 48,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No status updates',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...otherStatuses.entries.map((entry) {
                final userStatuses = entry.value;
                final latestStatus = userStatuses.first;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: RegentColors.green, width: 2),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _getTimeAgo(latestStatus.createdAt),
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatusScreen()),
                    );
                  },
                );
              }),
          ],
        );
      },
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
