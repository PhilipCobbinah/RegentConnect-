import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';

class CallScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientPhotoUrl;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhotoUrl,
    this.isVideoCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isCameraOff = false;
  bool isFrontCamera = true;
  bool isHandRaised = false;
  String callStatus = 'Calling...';
  final authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  bool _showMessages = false;
  final List<CallMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Simulate call connecting
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => callStatus = 'Connected');
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendEmoji(String emoji) {
    setState(() {
      _messages.add(CallMessage(
        type: 'emoji',
        content: emoji,
        sender: authService.currentUser?.displayName ?? 'You',
        timestamp: DateTime.now(),
      ));
    });
    
    // Show floating emoji briefly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji sent!'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  void _raiseHand() {
    setState(() => isHandRaised = !isHandRaised);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isHandRaised ? '✋ Hand raised' : '✋ Hand lowered'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleScreenShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📺 Screen share feature coming soon!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _sendChatMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(CallMessage(
        type: 'text',
        content: message,
        sender: authService.currentUser?.displayName ?? 'You',
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });
  }

  void _addFriend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Contacts'),
        content: Text('Add ${widget.recipientName} to your contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Contact added!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleCameraMode() {
    setState(() => isFrontCamera = !isFrontCamera);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFrontCamera ? '📷 Switched to front camera' : '📷 Switched to back camera',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _endCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('End Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Call View
            Column(
              children: [
                // Header with recipient info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: widget.recipientPhotoUrl != null
                            ? NetworkImage(widget.recipientPhotoUrl!)
                            : null,
                        child: widget.recipientPhotoUrl == null
                            ? Text(
                                widget.recipientName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.recipientName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              callStatus,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Main content area
                Expanded(
                  child: _showMessages
                      ? _buildMessageView()
                      : _buildCallView(),
                ),
              ],
            ),

            // Floating Action Buttons (Top Right)
            Positioned(
              top: 80,
              right: 16,
              child: Column(
                children: [
                  // Close Video Button
                  if (widget.isVideoCall)
                    Tooltip(
                      message: 'Close Video',
                      child: _buildFloatingButton(
                        icon: Icons.videocam_off,
                        backgroundColor: Colors.red,
                        onPressed: () => setState(() => isCameraOff = !isCameraOff),
                      ),
                    ),
                  const SizedBox(height: 8),
                  
                  // Share Screen Button
                  Tooltip(
                    message: 'Share Screen',
                    child: _buildFloatingButton(
                      icon: Icons.screenshot_monitor,
                      onPressed: _toggleScreenShare,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Raise Hand Button
                  Tooltip(
                    message: isHandRaised ? 'Lower Hand' : 'Raise Hand',
                    child: _buildFloatingButton(
                      icon: Icons.pan_tool,
                      backgroundColor: isHandRaised ? Colors.orange : Colors.blue,
                      onPressed: _raiseHand,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Control Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Emoji Reactions
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['👍', '❤️', '😂', '🔥', '😍', '👏', '🎉', '😮']
                            .map((emoji) => GestureDetector(
                                  onTap: () => _sendEmoji(emoji),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute Button
                        Tooltip(
                          message: isMuted ? 'Unmute' : 'Mute',
                          child: _buildControlButton(
                            icon: isMuted ? Icons.mic_off : Icons.mic,
                            label: isMuted ? 'Unmute' : 'Mute',
                            isActive: isMuted,
                            onPressed: () => setState(() => isMuted = !isMuted),
                          ),
                        ),

                        // Camera Toggle (Selfie/Back)
                        if (widget.isVideoCall)
                          Tooltip(
                            message: isFrontCamera ? 'Back Camera' : 'Front Camera',
                            child: _buildControlButton(
                              icon: isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                              label: isFrontCamera ? 'Front' : 'Back',
                              onPressed: _toggleCameraMode,
                            ),
                          ),

                        // Camera Off Button
                        if (widget.isVideoCall)
                          Tooltip(
                            message: isCameraOff ? 'Turn Camera On' : 'Turn Camera Off',
                            child: _buildControlButton(
                              icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
                              label: isCameraOff ? 'Cam Off' : 'Cam On',
                              isActive: isCameraOff,
                              onPressed: () => setState(() => isCameraOff = !isCameraOff),
                            ),
                          ),

                        // Speaker Button
                        if (!widget.isVideoCall)
                          Tooltip(
                            message: isSpeakerOn ? 'Speaker Off' : 'Speaker On',
                            child: _buildControlButton(
                              icon: isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                              label: isSpeakerOn ? 'Speaker' : 'Phone',
                              isActive: isSpeakerOn,
                              onPressed: () => setState(() => isSpeakerOn = !isSpeakerOn),
                            ),
                          ),

                        // Message Button
                        Tooltip(
                          message: 'Chat',
                          child: _buildControlButton(
                            icon: Icons.message,
                            label: 'Chat',
                            onPressed: () => setState(() => _showMessages = !_showMessages),
                          ),
                        ),

                        // Add Friend Button
                        Tooltip(
                          message: 'Add Contact',
                          child: _buildControlButton(
                            icon: Icons.person_add,
                            label: 'Add',
                            onPressed: _addFriend,
                          ),
                        ),

                        // Hang Up Button (Red)
                        Tooltip(
                          message: 'End Call',
                          child: _buildControlButton(
                            icon: Icons.call_end,
                            label: 'End',
                            backgroundColor: Colors.red,
                            onPressed: _endCall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: widget.recipientPhotoUrl != null
                  ? NetworkImage(widget.recipientPhotoUrl!)
                  : null,
              child: widget.recipientPhotoUrl == null
                  ? Text(
                      widget.recipientName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 72),
                    )
                  : null,
            ),
            const SizedBox(height: 32),
            Text(
              widget.recipientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (callStatus == 'Connected')
              const Text(
                '📞 In call',
                style: TextStyle(color: Colors.green, fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageView() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.sender == (authService.currentUser?.displayName ?? 'You');
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? RegentColors.blue : Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: msg.type == 'emoji'
                            ? Text(msg.content, style: const TextStyle(fontSize: 24))
                            : Text(msg.content, style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendChatMessage(),
                  decoration: InputDecoration(
                    hintText: 'Send a message...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white12,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendChatMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: RegentColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    Color backgroundColor = Colors.white24,
    bool isActive = false,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : backgroundColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: isActive ? Colors.black : Colors.white),
            iconSize: 28,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    Color backgroundColor = Colors.blue,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class CallMessage {
  final String type; // 'text' or 'emoji'
  final String content;
  final String sender;
  final DateTime timestamp;

  CallMessage({
    required this.type,
    required this.content,
    required this.sender,
    required this.timestamp,
  });
}

// Call History Screen
class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: RegentColors.blue,
        title: const Text('Calls', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No call history', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              'Audio and video calls coming soon!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
