import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../services/ai_service.dart';
import '../../../services/auth_service.dart';

class RegentAIScreen extends StatefulWidget {
  const RegentAIScreen({super.key});

  @override
  State<RegentAIScreen> createState() => _RegentAIScreenState();
}

class _RegentAIScreenState extends State<RegentAIScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final AIService _aiService = AIService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  // New: for image preview before sending
  Uint8List? _pendingImageData;
  String? _pendingImageSource;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final userName = _authService.currentUser?.displayName ?? 'Student';
    _messages.add(ChatMessage(
      content: '''Hi $userName! 👋 I'm **Regent AI**, your personal academic assistant.

I can help you with:
📚 **Academic Questions** - Any subject or topic
💻 **Programming Help** - Code explanations & debugging
📸 **Photo Analysis** - Upload images for solutions
🎤 **Audio Notes** - Record and transcribe your questions
📝 **Study Tips** - Exam prep & learning strategies
🎯 **Career Guidance** - Future planning & advice

How can I assist you today?''',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiService.sendMessage(message);
      
      setState(() {
        _messages.add(ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _captureFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        _showImagePreview(imageBytes, 'camera');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _uploadFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        _showImagePreview(imageBytes, 'gallery');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showImagePreview(Uint8List imageBytes, String source) {
    setState(() {
      _pendingImageData = imageBytes;
      _pendingImageSource = source;
    });
  }

  void _cancelImagePreview() {
    setState(() {
      _pendingImageData = null;
      _pendingImageSource = null;
      _messageController.clear();
    });
  }

  Future<void> _sendImageWithMessage() async {
    if (_pendingImageData == null || _isLoading) return;

    final userMessage = _messageController.text.trim();
    final imageData = _pendingImageData!;
    final source = _pendingImageSource ?? 'image';

    setState(() {
      _messages.add(ChatMessage(
        content: userMessage.isNotEmpty ? userMessage : 'Analyze this image',
        isUser: true,
        timestamp: DateTime.now(),
        imageData: imageData,
      ));
      _pendingImageData = null;
      _pendingImageSource = null;
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Send image to AI for analysis with user's message
      final response = await _aiService.analyzeImageWithPrompt(
        imageData, 
        'image/jpeg',
        userMessage.isNotEmpty ? userMessage : 'Please analyze this image and provide helpful information.',
      );

      setState(() {
        _messages.add(ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          content: 'Error analyzing image: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _showAudioOptions() {
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
                'Audio Input',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.mic, color: Colors.red, size: 32),
                title: const Text('Record Audio Note'),
                subtitle: const Text('Record and transcribe your question'),
                onTap: () {
                  Navigator.pop(context);
                  _recordAudioNote();
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.blue, size: 32),
                title: const Text('Upload Audio File'),
                subtitle: const Text('Upload an existing audio file'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Audio file upload coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _recordAudioNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Audio Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Recording feature coming soon!'),
            const SizedBox(height: 8),
            const Text(
              'You will be able to record audio notes and get AI-powered transcription and solutions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _aiService.resetChat();
                _addWelcomeMessage();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade700,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy, color: Colors.purple, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Regent AI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'Your Academic Assistant',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Tooltip(
            message: 'Clear Chat',
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearChat,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'suggestions') {
                _showSuggestions();
              } else if (value == 'about') {
                _showAbout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suggestions',
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline),
                    SizedBox(width: 8),
                    Text('Suggestions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Quick Actions
          if (_messages.length <= 1 && _pendingImageData == null) _buildQuickActions(),

          // Image Preview (when image is selected)
          if (_pendingImageData != null) _buildImagePreview(),

          // Input Field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Regent AI Triangle Design
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A148C).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CustomPaint(
              painter: TrianglePainter(scale: 2.0),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Regent AI',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your intelligent academic assistant',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyMessage(message.content),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? Colors.purple : Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show image if exists
                    if (message.imageData != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          message.imageData!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildFormattedText(
                      message.content,
                      isUser ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: RegentColors.blue,
              child: Text(
                _authService.currentUser?.displayName?[0].toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, Color color) {
    return SelectableText(
      text.replaceAll('**', '').replaceAll('`', ''),
      style: TextStyle(color: color, fontSize: 15, height: 1.4),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.purple,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final suggestions = [
      '📚 Explain a concept',
      '💻 Help with code',
      '📝 Study tips',
      '🎯 Career advice',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  _messageController.text = suggestion.substring(2).trim();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Image ready to send',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _cancelImagePreview,
                tooltip: 'Remove image',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _pendingImageData!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // Message input for image
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a message (optional):',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 2,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'E.g., "Solve this math problem" or "Explain this diagram"',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Container(
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading ? null : _sendImageWithMessage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Suggestion chips for image
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildImageSuggestionChip('Solve this problem'),
                _buildImageSuggestionChip('Explain this'),
                _buildImageSuggestionChip('Translate this text'),
                _buildImageSuggestionChip('What is this?'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.purple.withOpacity(0.1),
        side: BorderSide(color: Colors.purple.withOpacity(0.3)),
        onPressed: () {
          _messageController.text = text;
        },
      ),
    );
  }

  Widget _buildInputField() {
    // Hide input field buttons when image preview is showing
    if (_pendingImageData != null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Camera Button
            Tooltip(
              message: 'Take Photo',
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.purple),
                onPressed: _captureFromCamera,
              ),
            ),

            // Gallery Button
            Tooltip(
              message: 'Upload Photo',
              child: IconButton(
                icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                onPressed: _uploadFromGallery,
              ),
            ),

            // Text Input
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask Regent AI anything...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Microphone Button
            Tooltip(
              message: 'Voice Note',
              child: IconButton(
                icon: const Icon(Icons.mic, color: Colors.red),
                onPressed: _showAudioOptions,
              ),
            ),

            // Send Button
            Container(
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showSuggestions() {
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
            const Text(
              'Try asking about:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSuggestionTile(
              'Explain the concept of Object-Oriented Programming',
              Icons.code,
            ),
            _buildSuggestionTile(
              'What are some effective study techniques for exams?',
              Icons.school,
            ),
            _buildSuggestionTile(
              'Help me understand database normalization',
              Icons.storage,
            ),
            _buildSuggestionTile(
              'Analyze this math problem from my photo',
              Icons.camera_alt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(String text, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(text, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.purple),
            SizedBox(width: 8),
            Text('About Regent AI'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regent AI is your personal academic assistant powered by advanced AI.',
            ),
            SizedBox(height: 16),
            Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Answer academic questions'),
            Text('• Analyze images (math, diagrams, etc)'),
            Text('• Transcribe audio notes'),
            Text('• Help with programming'),
            Text('• Provide study tips'),
            Text('• Career guidance'),
            SizedBox(height: 16),
            Text(
              'Note: Always verify important information from official sources.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageData;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.imageData,
  });
}

// Add this class at the end of the file
class TrianglePainter extends CustomPainter {
  final double scale;

  TrianglePainter({this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final scaledSize = Size(size.width * scale, size.height * scale);
    final rect = Rect.fromLTWH(0, 0, scaledSize.width, scaledSize.height);
    
    // Main violet gradient triangle
    final violetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF4A148C), // Deep violet
          const Color(0xFF7B1FA2), // Purple
        ],
      ).createShader(rect);

    // Cream accent
    final creamPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFFFFF8E1), // Cream
          Color(0xFFFFECB3), // Light cream
        ],
      ).createShader(rect);

    // Draw rounded triangle shape
    final path = Path();
    
    const radius = 12.0;
    final centerX = scaledSize.width / 2;
    
    // Triangle points
    final topPoint = Offset(centerX, 4);
    final bottomLeftPoint = Offset(4, scaledSize.height - 4);
    final bottomRightPoint = Offset(scaledSize.width - 4, scaledSize.height - 4);
    
    path.moveTo(topPoint.dx, topPoint.dy + radius);
    
    // Top to bottom right
    path.quadraticBezierTo(
      topPoint.dx + radius / 2, topPoint.dy,
      topPoint.dx + radius, topPoint.dy + radius / 2,
    );
    path.lineTo(bottomRightPoint.dx - radius, bottomRightPoint.dy - radius);
    
    // Bottom right corner
    path.quadraticBezierTo(
      bottomRightPoint.dx, bottomRightPoint.dy - radius / 2,
      bottomRightPoint.dx, bottomRightPoint.dy,
    );
    path.quadraticBezierTo(
      bottomRightPoint.dx - radius / 2, bottomRightPoint.dy,
      bottomRightPoint.dx - radius, bottomRightPoint.dy,
    );
    
    // Bottom right to bottom left
    path.lineTo(bottomLeftPoint.dx + radius, bottomLeftPoint.dy);
    
    // Bottom left corner
    path.quadraticBezierTo(
      bottomLeftPoint.dx + radius / 2, bottomLeftPoint.dy,
      bottomLeftPoint.dx, bottomLeftPoint.dy,
    );
    path.quadraticBezierTo(
      bottomLeftPoint.dx, bottomLeftPoint.dy - radius / 2,
      bottomLeftPoint.dx + radius, bottomLeftPoint.dy - radius,
    );
    
    // Bottom left to top
    path.lineTo(topPoint.dx - radius, topPoint.dy + radius / 2);
    path.quadraticBezierTo(
      topPoint.dx - radius / 2, topPoint.dy,
      topPoint.dx, topPoint.dy + radius,
    );
    
    path.close();

    // Draw main shape
    canvas.drawPath(path, violetPaint);
    
    // Draw cream accent triangle (smaller, at top-right)
    final accentPath = Path();
    accentPath.moveTo(scaledSize.width - 8, 16);
    accentPath.lineTo(scaledSize.width - 8, 28);
    accentPath.lineTo(scaledSize.width - 20, 22);
    accentPath.close();
    
    canvas.drawPath(accentPath, creamPaint);
    
    // Draw another cream accent (bottom-left)
    final accentPath2 = Path();
    accentPath2.moveTo(12, scaledSize.height - 12);
    accentPath2.lineTo(24, scaledSize.height - 12);
    accentPath2.lineTo(18, scaledSize.height - 22);
    accentPath2.close();
    
    canvas.drawPath(accentPath2, creamPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
