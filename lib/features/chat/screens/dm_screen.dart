import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../services/chat_service.dart';
import '../../../services/call_service.dart';
import '../../../services/notification_service.dart';
import '../../calls/screens/video_call_screen.dart';
import '../../../widgets/active_call_overlay.dart';

class DMScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientPhoto;

  const DMScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhoto,
  });

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _callService = CallService();
  final _scrollController = ScrollController();
  
  bool _isSending = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  Map<String, dynamic>? _replyingTo;
  String? _selectedMessageId;

  // Quick reaction emojis
  final List<String> _quickReactions = ['👍', '❤️', '😂', '😢', '👏', '🔥', '😮', '🎉'];

  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _messageSubscription;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(widget.recipientId);
    
    // Add listener for text changes to detect typing
    _messageController.addListener(_onTextChanged);
    _listenForNewMessages();
  }

  void _listenForNewMessages() {
    _messageSubscription = _chatService.getMessages(widget.recipientId).listen((snapshot) {
      if (snapshot.docs.length > _previousMessageCount && _previousMessageCount > 0) {
        // New message received
        final latestMessage = snapshot.docs.last.data() as Map<String, dynamic>;
        if (latestMessage['senderId'] != _chatService.currentUserId) {
          // Play sound only for received messages
          _notificationService.playMessageSound();
        }
      }
      _previousMessageCount = snapshot.docs.length;
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.removeListener(_onTextChanged);
    _typingTimer?.cancel();
    // Clear typing status when leaving
    _chatService.setTypingStatus(widget.recipientId, false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.setTypingStatus(widget.recipientId, true);
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _chatService.setTypingStatus(widget.recipientId, false);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    await _chatService.sendMessage(
      receiverId: widget.recipientId,
      message: message,
    );

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    setState(() => _isSending = true);
    final url = await _chatService.uploadMedia(File(image.path), 'images');
    if (url != null) {
      await _chatService.sendMessage(
        receiverId: widget.recipientId,
        message: '📷 Photo',
        type: 'image',
        mediaUrl: url,
      );
    }
    setState(() => _isSending = false);
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    setState(() => _isSending = true);
    final url = await _chatService.uploadMedia(File(video.path), 'videos');
    if (url != null) {
      await _chatService.sendMessage(
        receiverId: widget.recipientId,
        message: '🎬 Video',
        type: 'video',
        mediaUrl: url,
      );
    }
    setState(() => _isSending = false);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    setState(() => _isSending = true);
    final url = await _chatService.uploadMedia(file, 'files');
    if (url != null) {
      await _chatService.sendMessage(
        receiverId: widget.recipientId,
        message: '📎 ${result.files.single.name}',
        type: 'file',
        mediaUrl: url,
      );
    }
    setState(() => _isSending = false);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: RegentColors.dmSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(Icons.photo, 'Gallery', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
                _attachmentOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _attachmentOption(Icons.videocam, 'Video', () {
                  Navigator.pop(context);
                  _pickVideo();
                }),
                _attachmentOption(Icons.attach_file, 'File', () {
                  Navigator.pop(context);
                  _pickFile();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: RegentColors.violet,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  void _startCall(bool isVideo) async {
    final currentUserData = await _chatService.getUserData(_chatService.currentUserId);
    final callerName = currentUserData?['fullName'] ?? currentUserData?['email'] ?? 'Unknown';
    final callerPhoto = currentUserData?['photoUrl'];

    final callId = await _callService.initiateCall(
      receiverId: widget.recipientId,
      receiverName: widget.recipientName,
      callerName: callerName,
      isVideo: isVideo,
      callerPhoto: callerPhoto,
      receiverPhoto: widget.recipientPhoto,
    );

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            callId: callId,
            recipientId: widget.recipientId,
            recipientName: widget.recipientName,
            recipientPhoto: widget.recipientPhoto,
            isVideo: isVideo,
          ),
        ),
      );

      // If call was minimized, update the active call overlay
      if (result != null && result is Map && result['minimized'] == true) {
        final callData = result['callData'] as Map<String, dynamic>?;
        if (callData != null) {
          activeCallOverlayKey.currentState?.setMinimizedCall(callData);
        }
      }
    }
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');

    if (messageDate == today) {
      return time;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $time';
    } else if (now.difference(date).inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[date.weekday - 1]} $time';
    } else {
      return '$day/$month/$year $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegentColors.dmBackground,
      appBar: AppBar(
        backgroundColor: RegentColors.dmSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: RegentColors.violet,
              backgroundImage: widget.recipientPhoto != null
                  ? NetworkImage(widget.recipientPhoto!)
                  : null,
              child: widget.recipientPhoto == null
                  ? Text(
                      widget.recipientName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Typing indicator or online status
                  StreamBuilder<DocumentSnapshot>(
                    stream: _chatService.getTypingStatus(widget.recipientId),
                    builder: (context, typingSnapshot) {
                      if (typingSnapshot.hasData && typingSnapshot.data!.exists) {
                        final data = typingSnapshot.data!.data() as Map<String, dynamic>?;
                        final typing = data?['typing'] as Map<String, dynamic>?;
                        final isRecipientTyping = typing?[widget.recipientId] != null;
                        
                        if (isRecipientTyping) {
                          return const Text(
                            'typing...',
                            style: TextStyle(
                              color: RegentColors.lightViolet,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                      }
                      
                      // Show online status if not typing
                      return StreamBuilder<DocumentSnapshot>(
                        stream: _chatService.getUserStream(widget.recipientId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final isOnline = data?['isOnline'] ?? false;
                          return Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? Colors.greenAccent : Colors.white54,
                              fontSize: 12,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () => _startCall(false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () => _startCall(true),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: RegentColors.dmCard,
            onSelected: (value) {
              if (value == 'clear') {
                _showClearChatDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear chat', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.recipientId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: RegentColors.violet));
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _chatService.currentUserId;
                    
                    // Check if we should show date header
                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true;
                    } else {
                      final prevData = messages[index - 1].data() as Map<String, dynamic>;
                      final prevTimestamp = prevData['timestamp'] as Timestamp?;
                      final currTimestamp = data['timestamp'] as Timestamp?;
                      if (prevTimestamp != null && currTimestamp != null) {
                        final prevDate = prevTimestamp.toDate();
                        final currDate = currTimestamp.toDate();
                        showDateHeader = prevDate.day != currDate.day ||
                            prevDate.month != currDate.month ||
                            prevDate.year != currDate.year;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(data['timestamp'] as Timestamp?),
                        _buildMessageBubble(data, isMe, messages[index].id),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Typing indicator at bottom
          StreamBuilder<DocumentSnapshot>(
            stream: _chatService.getTypingStatus(widget.recipientId),
            builder: (context, typingSnapshot) {
              if (typingSnapshot.hasData && typingSnapshot.data!.exists) {
                final data = typingSnapshot.data!.data() as Map<String, dynamic>?;
                final typing = data?['typing'] as Map<String, dynamic>?;
                final typingUserName = typing?[widget.recipientId];
                
                if (typingUserName != null) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        _buildTypingAnimation(),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.recipientName} is typing...',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation() {
    return SizedBox(
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 600 + (index * 200)),
            builder: (context, value, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: RegentColors.violet.withOpacity(0.5 + (value * 0.5)),
                  shape: BoxShape.circle,
                ),
              );
            },
            onEnd: () {},
          );
        }),
    );
  }

  Widget _buildDateHeader(Timestamp? timestamp) {
    if (timestamp == null) return const SizedBox();
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (messageDate == today) {
      dateStr = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RegentColors.dmCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateStr,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe, String messageId) {
    final type = data['type'] ?? 'text';
    final timestamp = data['timestamp'] as Timestamp?;
    final time = _formatMessageTime(timestamp);
    final isDeleted = data['isDeleted'] == true;
    final deletedForEveryone = data['deletedForEveryone'] == true;
    final deletedByName = data['deletedByName'] ?? 'Someone';
    final deletedBy = data['deletedBy'];
    
    // Check if message was deleted for me only
    final deletedForMe = data['deletedForMe'] == true && deletedBy == _chatService.currentUserId;
    
    // If deleted for me only, don't show to me
    if (deletedForMe && !deletedForEveryone) {
      return const SizedBox.shrink();
    }
    
    // If deleted for everyone, show deleted placeholder
    if (deletedForEveryone) {
      return _buildDeletedMessageBubble(isMe, deletedByName, deletedBy == _chatService.currentUserId, time);
    }

    final reactions = Map<String, List<String>>.from(
      (data['reactions'] ?? {}).map((key, value) => MapEntry(key, List<String>.from(value))),
    );
    final isStarred = data['starredBy']?.contains(_chatService.currentUserId) ?? false;
    final replyTo = data['replyTo'] as Map<String, dynamic>?;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, data, isMe, messageId),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Reply preview
            if (replyTo != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 50 : 0,
                  right: isMe ? 0 : 50,
                  bottom: 4,
                ),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RegentColors.dmCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(
                      color: RegentColors.violet,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replyTo['senderName'] ?? 'Unknown',
                      style: const TextStyle(
                        color: RegentColors.lightViolet,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      replyTo['message'] ?? '',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            // Message bubble
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMe ? RegentColors.violet : RegentColors.dmCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name for received messages
                  if (!isMe && data['senderName'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        data['senderName'],
                        style: const TextStyle(
                          color: RegentColors.lightViolet,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Message content
                  if (type == 'text')
                    Text(
                      data['message'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    )
                  else if (type == 'image')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['mediaUrl'] ?? '',
                        width: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 200,
                            height: 150,
                            child: Center(child: CircularProgressIndicator(color: Colors.white)),
                          );
                        },
                      ),
                    )
                  else
                    Text(
                      data['message'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  const SizedBox(height: 4),
                  // Time and status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isStarred)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.star, size: 12, color: Colors.amber),
                        ),
                      Text(
                        time,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          data['isRead'] == true ? Icons.done_all : Icons.done,
                          size: 14,
                          color: data['isRead'] == true ? Colors.lightBlueAccent : Colors.white60,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Reactions display
            if (reactions.isNotEmpty)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 0 : 12,
                  right: isMe ? 12 : 0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RegentColors.dmSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RegentColors.dmCard),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: reactions.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () => _toggleReaction(messageId, entry.key),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: 14)),
                            if (entry.value.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Text(
                                  '${entry.value.length}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedMessageBubble(bool isMe, String deletedByName, bool deletedByCurrentUser, String time) {
    final displayText = deletedByCurrentUser 
        ? 'You deleted this message' 
        : '$deletedByName deleted this message';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: (isMe ? RegentColors.violet : RegentColors.dmCard).withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Map<String, dynamic> data, bool isMe, String messageId) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: RegentColors.dmSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Quick reactions row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ..._quickReactions.map((emoji) => _buildReactionButton(emoji, messageId)),
                  _buildAddEmojiButton(messageId),
                ],
              ),
            ),
            const Divider(color: RegentColors.dmCard, height: 1),
            // Message options
            _buildOptionTile(Icons.reply, 'Reply', () {
              Navigator.pop(context);
              _setReplyTo(data);
            }),
            _buildOptionTile(Icons.forward, 'Forward', () {
              Navigator.pop(context);
              _forwardMessage(data);
            }),
            _buildOptionTile(Icons.copy, 'Copy', () {
              Navigator.pop(context);
              _copyMessage(data['message'] ?? '');
            }),
            _buildOptionTile(
              data['starredBy']?.contains(_chatService.currentUserId) == true
                  ? Icons.star
                  : Icons.star_border,
              data['starredBy']?.contains(_chatService.currentUserId) == true
                  ? 'Unstar'
                  : 'Star',
              () {
                Navigator.pop(context);
                _toggleStar(messageId);
              },
            ),
            if (isMe)
              _buildOptionTile(Icons.delete, 'Delete', () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              }, isDestructive: true),
            _buildOptionTile(Icons.more_horiz, 'More', () {
              Navigator.pop(context);
              _showMoreOptions(context, data, isMe, messageId);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(String emoji, String messageId) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _toggleReaction(messageId, emoji);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: RegentColors.dmCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildAddEmojiButton(String messageId) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showEmojiPicker(messageId);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: RegentColors.dmCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white),
      ),
      onTap: onTap,
    );
  }

  void _showMoreOptions(BuildContext context, Map<String, dynamic> data, bool isMe, String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RegentColors.dmSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
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
          _buildOptionTile(Icons.push_pin, 'Pin message', () {
            Navigator.pop(context);
            _pinMessage(messageId);
          }),
          _buildOptionTile(Icons.report, 'Report', () {
            Navigator.pop(context);
            _reportMessage(messageId);
          }),
          _buildOptionTile(Icons.quick_contacts_mail, 'Add quick reply', () {
            Navigator.pop(context);
            _addQuickReply(data['message'] ?? '');
          }),
          if (isMe)
            _buildOptionTile(Icons.delete_forever, 'Delete for everyone', () {
              Navigator.pop(context);
              _deleteForEveryone(messageId);
            }, isDestructive: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEmojiPicker(String messageId) {
    final allEmojis = [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
      '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😋',
      '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
      '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥', '😌',
      '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🤧',
      '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐',
      '😕', '😟', '🙁', '☹️', '😮', '😯', '😲', '😳', '🥺', '😦',
      '😧', '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞',
      '😓', '😩', '😫', '🥱', '😤', '😡', '😠', '🤬', '😈', '👿',
      '👍', '👎', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✊', '👊',
      '🤛', '🤜', '🤞', '✌️', '🤟', '🤘', '👌', '🤏', '👈', '👉',
      '👆', '👇', '☝️', '✋', '🤚', '🖐', '🖖', '👋', '🤙', '💪',
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️',
      '🔥', '✨', '🎉', '🎊', '🎁', '🏆', '🥇', '🥈', '🥉', '⭐',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: RegentColors.dmSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
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
                'Choose a reaction',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: allEmojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _toggleReaction(messageId, allEmojis[index]);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: RegentColors.dmCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(allEmojis[index], style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setReplyTo(Map<String, dynamic> message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    await _chatService.toggleReaction(widget.recipientId, messageId, emoji);
  }

  Future<void> _toggleStar(String messageId) async {
    await _chatService.toggleStar(widget.recipientId, messageId);
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        backgroundColor: RegentColors.violet,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _forwardMessage(Map<String, dynamic> message) {
    _showForwardDialog(message);
  }

  void _showForwardDialog(Map<String, dynamic> message) {
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
                'Forward to',
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

                  final users = snapshot.data!.docs
                      .where((doc) => doc.id != _chatService.currentUserId)
                      .toList();

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
                        onTap: () async {
                          Navigator.pop(context);
                          await _chatService.sendMessage(
                            receiverId: userId,
                            message: message['message'] ?? '',
                            type: message['type'] ?? 'text',
                            mediaUrl: message['mediaUrl'],
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Message forwarded to $userName'),
                                backgroundColor: RegentColors.violet,
                              ),
                            );
                          }
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

  void _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RegentColors.dmSurface,
        title: const Text('Delete message', style: TextStyle(color: Colors.white)),
        content: const Text('Delete this message for you?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _chatService.deleteMessage(widget.recipientId, messageId);
    }
  }

  void _deleteForEveryone(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RegentColors.dmSurface,
        title: const Text('Delete for everyone', style: TextStyle(color: Colors.white)),
        content: const Text('This message will be deleted for everyone in this chat.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _chatService.deleteForEveryone(widget.recipientId, messageId);
    }
  }

  void _pinMessage(String messageId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message pinned'), backgroundColor: RegentColors.violet),
    );
  }

  void _reportMessage(String messageId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message reported'), backgroundColor: RegentColors.violet),
    );
  }

  void _addQuickReply(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to quick replies'), backgroundColor: RegentColors.violet),
    );
  }

  // Update _buildInputArea to show reply preview
  Widget _buildInputArea() {
    return Column(
      children: [
        // Reply preview
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: RegentColors.dmCard,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  color: RegentColors.violet,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _replyingTo!['senderName'] ?? 'Unknown',
                        style: TextStyle(
                          color: RegentColors.lightViolet,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _replyingTo!['message'] ?? '',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: _cancelReply,
                ),
              ],
            ),
          ),
        // Input area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: RegentColors.dmSurface,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: RegentColors.violet),
                onPressed: _showAttachmentOptions,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: RegentColors.dmCard,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (text) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: RegentColors.violet, strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: RegentColors.violet),
                      onPressed: _sendMessageWithReply,
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessageWithReply() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    await _chatService.sendMessage(
      receiverId: widget.recipientId,
      message: message,
      replyTo: _replyingTo,
    );

    setState(() {
      _isSending = false;
      _replyingTo = null;
    });
    _scrollToBottom();
  }
}
