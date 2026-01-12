import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme_provider.dart';
import '../../../core/theme.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.call, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No recent calls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your call history will appear here',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/users'),
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
}
