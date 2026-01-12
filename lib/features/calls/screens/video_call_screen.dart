import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import '../../../services/call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String recipientId;
  final String recipientName;
  final String? recipientPhoto;
  final bool isVideo;
  final bool isIncoming;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhoto,
    required this.isVideo,
    this.isIncoming = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final CallService _callService = CallService();
  
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = true;
  bool _isMinimized = false;
  String _callStatus = 'Calling...';
  int _callDuration = 0;
  Timer? _callTimer;
  StreamSubscription? _callStatusSubscription;

  @override
  void initState() {
    super.initState();
    _setupCall();
  }

  void _setupCall() {
    _callStatusSubscription = _callService.listenToCallStatus(widget.callId).listen((snapshot) {
      if (!snapshot.exists) {
        _endCall(showMessage: false);
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'] as String;
      final isReceiverOnline = data['isReceiverOnline'] ?? false;

      setState(() {
        switch (status) {
          case 'calling':
            _callStatus = isReceiverOnline ? 'Calling...' : 'User offline...';
            break;
          case 'ringing':
            _callStatus = 'Ringing...';
            break;
          case 'connecting':
            _callStatus = 'Connecting...';
            break;
          case 'connected':
            _callStatus = 'Connected';
            _startCallTimer();
            break;
          case 'declined':
            _callStatus = 'Call declined';
            Future.delayed(const Duration(seconds: 2), () => _endCall(showMessage: false));
            break;
          case 'ended':
            _endCall(showMessage: false);
            break;
          case 'missed':
            _callStatus = 'No answer';
            Future.delayed(const Duration(seconds: 2), () => _endCall(showMessage: false));
            break;
        }
      });
    });

    // Auto-end call if not answered in 60 seconds
    if (!widget.isIncoming) {
      Future.delayed(const Duration(seconds: 60), () {
        if (_callStatus == 'Calling...' || _callStatus == 'Ringing...' || _callStatus == 'User offline...') {
          _callService.updateCallStatus(widget.callId, 'missed');
        }
      });
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _endCall({bool showMessage = true}) {
    _callTimer?.cancel();
    _callStatusSubscription?.cancel();
    _callService.endCall(widget.callId, widget.recipientId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _minimizeCall() {
    // Return call data so overlay can track it
    Navigator.of(context).pop({
      'minimized': true,
      'callId': widget.callId,
      'callData': {
        'callId': widget.callId,
        'callerId': widget.isIncoming ? widget.recipientId : _callService.currentUserId,
        'callerName': widget.isIncoming ? widget.recipientName : 'You',
        'callerPhoto': widget.isIncoming ? widget.recipientPhoto : null,
        'receiverId': widget.isIncoming ? _callService.currentUserId : widget.recipientId,
        'receiverName': widget.isIncoming ? 'You' : widget.recipientName,
        'receiverPhoto': widget.isIncoming ? null : widget.recipientPhoto,
        'isVideo': widget.isVideo,
        'status': _callStatus == 'Connected' ? 'connected' : 'connecting',
      },
    });
  }

  void _toggleMute() => setState(() => _isMuted = !_isMuted);
  void _toggleSpeaker() => setState(() => _isSpeakerOn = !_isSpeakerOn);
  void _toggleVideo() => setState(() => _isVideoOn = !_isVideoOn);

  @override
  void dispose() {
    _callTimer?.cancel();
    _callStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _minimizeCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: RegentColors.dmBackground,
        body: SafeArea(
          child: Stack(
            children: [
              // Background / Video area
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      RegentColors.dmBackground,
                      RegentColors.violet.withOpacity(0.3),
                      RegentColors.dmBackground,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status indicator
                    _buildStatusIndicator(),
                    const SizedBox(height: 20),
                    // Recipient avatar
                    _buildAvatar(),
                    const SizedBox(height: 24),
                    // Recipient name
                    Text(
                      widget.recipientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Call status/duration
                    Text(
                      _callStatus == 'Connected' ? _formatDuration(_callDuration) : _callStatus,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Call type indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isVideo ? Icons.videocam : Icons.call,
                          color: RegentColors.violet,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isVideo ? 'Video Call' : 'Voice Call',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Self video preview (if video call)
              if (widget.isVideo && _isVideoOn)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: RegentColors.dmCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RegentColors.violet, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white54, size: 40),
                    ),
                  ),
                ),

              // Minimize button (top left)
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _minimizeCall,
                  tooltip: 'Minimize call',
                ),
              ),

              // Control buttons
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Secondary controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          onPressed: _toggleMute,
                          isActive: _isMuted,
                        ),
                        const SizedBox(width: 20),
                        _controlButton(
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          label: 'Speaker',
                          onPressed: _toggleSpeaker,
                          isActive: _isSpeakerOn,
                        ),
                        if (widget.isVideo) ...[
                          const SizedBox(width: 20),
                          _controlButton(
                            icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                            label: 'Camera',
                            onPressed: _toggleVideo,
                            isActive: !_isVideoOn,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 30),
                    // End call button
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    IconData icon;
    
    switch (_callStatus) {
      case 'Calling...':
        color = Colors.orange;
        icon = Icons.phone_forwarded;
        break;
      case 'Ringing...':
        color = Colors.amber;
        icon = Icons.ring_volume;
        break;
      case 'Connecting...':
        color = Colors.lightBlue;
        icon = Icons.sync;
        break;
      case 'Connected':
        color = Colors.greenAccent;
        icon = Icons.phone_in_talk;
        break;
      case 'User offline...':
        color = Colors.grey;
        icon = Icons.phone_disabled;
        break;
      default:
        color = Colors.redAccent;
        icon = Icons.phone_missed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            _callStatus,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_callStatus) {
      case 'Calling...':
        return Colors.orange;
      case 'Ringing...':
        return Colors.amber;
      case 'Connecting...':
        return Colors.lightBlue;
      case 'Connected':
        return Colors.greenAccent;
      case 'User offline...':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing animation for calling/ringing
        if (_callStatus == 'Calling...' || _callStatus == 'Ringing...')
          ...List.generate(3, (index) => _buildPulseCircle(index)),
        CircleAvatar(
          radius: 60,
          backgroundColor: RegentColors.violet,
          backgroundImage: widget.recipientPhoto != null
              ? NetworkImage(widget.recipientPhoto!)
              : null,
          child: widget.recipientPhoto == null
              ? Text(
                  widget.recipientName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        // Connected indicator
        if (_callStatus == 'Connected')
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildPulseCircle(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1500 + (index * 300)),
      builder: (context, value, child) {
        return Container(
          width: 120 + (value * 60 * (index + 1)),
          height: 120 + (value * 60 * (index + 1)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: RegentColors.violet.withOpacity(1 - value),
              width: 2,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && (_callStatus == 'Calling...' || _callStatus == 'Ringing...')) {
          setState(() {});
        }
      },
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? RegentColors.dmBackground : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
