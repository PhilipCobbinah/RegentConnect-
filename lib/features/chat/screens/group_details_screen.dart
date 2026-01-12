import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/group_model.dart';

class GroupDetailsScreen extends StatelessWidget {
  final GroupModel group;

  const GroupDetailsScreen({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final createdDate = DateFormat('MMM dd, yyyy').format(group.createdAt);
    final createdTime = DateFormat('hh:mm a').format(group.createdAt);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: RegentColors.blue,
        title: const Text('Group Info', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Profile
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: group.profilePictureUrl != null
                        ? NetworkImage(group.profilePictureUrl!)
                        : null,
                    backgroundColor: RegentColors.blue.withOpacity(0.2),
                    child: group.profilePictureUrl == null
                        ? Icon(
                            Icons.group,
                            size: 60,
                            color: RegentColors.blue,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${group.members.length} members',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description
            if (group.description.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(group.description),
              ),
              const SizedBox(height: 24),
            ],

            // Group Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RegentColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RegentColors.blue, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.person,
                    label: 'Created By',
                    value: group.creatorName,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Created On',
                    value: createdDate,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Created At',
                    value: createdTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Members Section
            const Text(
              'Members',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.members.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    index == 0 ? '${group.creatorName} (Creator)' : 'Member ${index + 1}',
                  ),
                  trailing: index == 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RegentColors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Creator',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: RegentColors.blue, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
