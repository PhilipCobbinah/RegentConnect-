import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/regent_ai_fab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: RegentColors.blue,
        title: const Text('Regent Connect', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  color: RegentColors.blue,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            user?.displayName?[0].toUpperCase() ?? '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: RegentColors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user?.displayName ?? 'Student'}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.chat,
                      title: 'Chats',
                      subtitle: 'Message students',
                      color: RegentColors.blue,
                      onTap: () => Navigator.pushNamed(context, '/chat-list'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.library_books,
                      title: 'Past Questions',
                      subtitle: 'Access exams',
                      color: RegentColors.green,
                      onTap: () => Navigator.pushNamed(context, '/past-questions'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.smart_toy,
                      title: 'Regent AI',
                      subtitle: 'Ask anything',
                      color: Colors.purple,
                      onTap: () => Navigator.pushNamed(context, '/ai-bot'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.donut_large,
                      title: 'Status',
                      subtitle: 'Share updates',
                      color: Colors.orange,
                      onTap: () => Navigator.pushNamed(context, '/status'),
                    ),
                  ],
                ),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
          // Regent AI Floating Button
          const RegentAICrystalFab(bottomOffset: 80),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
