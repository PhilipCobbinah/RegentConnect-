import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme.dart';
import '../../../services/status_service.dart';

class CreateStatusScreen extends StatefulWidget {
  final String type;
  final File? mediaFile;

  const CreateStatusScreen({
    super.key,
    required this.type,
    this.mediaFile,
  });

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final StatusService _statusService = StatusService();
  final TextEditingController _textController = TextEditingController();
  
  VideoPlayerController? _videoController;
  bool _isPosting = false;
  bool _allowReshare = true;
  bool _isMuted = false; // New: mute option for videos
  String _selectedColor = '#7C4DFF';
  
  final List<String> _backgroundColors = [
    '#7C4DFF', // Violet
    '#FF5722', // Orange
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#FF9800', // Amber
  ];

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video' && widget.mediaFile != null) {
      _videoController = VideoPlayerController.file(widget.mediaFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0 : 1);
    });
  }

  Future<void> _postStatus() async {
    if (_isPosting) return;

    setState(() => _isPosting = true);

    try {
      String? mediaUrl;
      
      if (widget.mediaFile != null) {
        mediaUrl = await _statusService.uploadStatusMedia(widget.mediaFile!, widget.type);
        if (mediaUrl == null) {
          throw Exception('Failed to upload media');
        }
      }

      await _statusService.postStatus(
        type: widget.type,
        text: _textController.text.isNotEmpty ? _textController.text : null,
        mediaUrl: mediaUrl,
        backgroundColor: _selectedColor,
        allowReshare: _allowReshare,
        isMuted: _isMuted, // Pass mute setting
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status posted!'),
            backgroundColor: RegentColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.type == 'text'
          ? Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
          : RegentColors.dmBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Mute toggle for video
          if (widget.type == 'video')
            IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: _isMuted ? Colors.redAccent : Colors.white,
              ),
              onPressed: _toggleMute,
              tooltip: _isMuted ? 'Unmute video' : 'Mute video',
            ),
          // Reshare toggle
          Row(
            children: [
              const Text('Reshare', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Switch(
                value: _allowReshare,
                onChanged: (value) => setState(() => _allowReshare = value),
                activeColor: RegentColors.violet,
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RegentColors.violet,
        onPressed: _isPosting ? null : _postStatus,
        icon: _isPosting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.send, color: Colors.white),
        label: Text(
          _isPosting ? 'Posting...' : 'Post Status',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.type == 'text') {
      return _buildTextStatus();
    } else if (widget.type == 'image') {
      return _buildImageStatus();
    } else {
      return _buildVideoStatus();
    }
  }

  Widget _buildTextStatus() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _textController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type a status...',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 24),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        // Color picker
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _backgroundColors.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: isSelected ? 40 : 32,
                  height: isSelected ? 40 : 32,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageStatus() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.mediaFile != null)
          Image.file(
            widget.mediaFile!,
            fit: BoxFit.contain,
          ),
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black45,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoStatus() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: RegentColors.violet)),
        
        // Mute indicator overlay
        if (_isMuted)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_off, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Video will be muted for viewers',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Caption input
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black45,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
