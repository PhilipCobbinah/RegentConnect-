import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../../models/group_model.dart';
import '../../../services/auth_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Uint8List? _groupProfileImage;
  final Set<String> _selectedMembers = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _groupProfileImage = bytes);
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final currentUser = authService.currentUser;
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
      String? profileUrl;

      // Upload group profile picture if selected
      if (_groupProfileImage != null) {
        final ref = _storage.ref().child('group_profiles/$groupId.jpg');
        await ref.putData(_groupProfileImage!);
        profileUrl = await ref.getDownloadURL();
      }

      // Add current user to members
      final members = [..._selectedMembers, currentUser!.uid];

      // Create group
      final group = GroupModel(
        id: groupId,
        name: _groupNameController.text.trim(),
        profilePictureUrl: profileUrl,
        createdBy: currentUser.uid,
        creatorName: currentUser.displayName ?? 'Unknown',
        creatorPhotoUrl: currentUser.photoURL,
        createdAt: DateTime.now(),
        members: members,
        description: _descriptionController.text.trim(),
      );

      await _firestore.collection('groups').doc(groupId).set(group.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, group);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    final gradientColor1 = isDark 
        ? const Color(0xFF1A1A2E) 
        : const Color(0xFF4A148C);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: gradientColor1,
        elevation: 0,
        title: const Text('Create Group', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Profile Picture
                  Center(
                    child: GestureDetector(
                      onTap: _pickGroupImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                          border: Border.all(color: RegentColors.blue, width: 2),
                        ),
                        child: _groupProfileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.memory(_groupProfileImage!, fit: BoxFit.cover),
                              )
                            : Icon(
                                Icons.camera_alt,
                                color: RegentColors.blue,
                                size: 40,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Group Name
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'Enter group name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Group Description
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'What\'s this group about?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Select Members
                  const Text(
                    'Select Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Members List
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users')
                        .where('uid', isNotEqualTo: authService.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userData = user.data() as Map<String, dynamic>;
                          final isSelected = _selectedMembers.contains(user.id);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: userData['photoUrl'] != null
                                  ? NetworkImage(userData['photoUrl'])
                                  : null,
                              child: userData['photoUrl'] == null
                                  ? Text(userData['displayName']?[0]?.toUpperCase() ?? '?')
                                  : null,
                            ),
                            title: Text(userData['displayName'] ?? 'Unknown'),
                            subtitle: Text(userData['program'] ?? ''),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value!) {
                                    _selectedMembers.add(user.id);
                                  } else {
                                    _selectedMembers.remove(user.id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMembers.remove(user.id);
                                } else {
                                  _selectedMembers.add(user.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Create Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RegentColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
