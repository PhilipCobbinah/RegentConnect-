import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/call_service.dart';
import 'video_call_screen.dart';
import '../../../widgets/active_call_overlay.dart';
import '../../../services/notification_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerPhoto;
  final bool isVideo;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.isVideo,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  final NotificationService _notificationService = NotificationService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _acceptCall() async {
    _notificationService.stopRingtone(); // Stop ringtone
    await _callService.acceptCall(widget.callId);
    if (mounted) {
      final result = await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            callId: widget.callId,
            recipientId: widget.callerId,
            recipientName: widget.callerName,
            recipientPhoto: widget.callerPhoto,
            isVideo: widget.isVideo,
            isIncoming: true,
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

  void _declineCall() async {
    _notificationService.stopRingtone(); // Stop ringtone
    await _callService.declineCall(widget.callId, widget.callerId);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegentColors.dmBackground,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                RegentColors.violet.withOpacity(0.3),
                RegentColors.dmBackground,
                RegentColors.dmBackground,
              ],
            ),
          ),
          child: Column(
            children: [
              const Spacer(),
              // Call type
              Text(
                widget.isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              // Caller avatar with pulse animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: RegentColors.violet.withOpacity(0.5),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: RegentColors.violet,
                        backgroundImage: widget.callerPhoto != null
                            ? NetworkImage(widget.callerPhoto!)
                            : null,
                        child: widget.callerPhoto == null
                            ? Text(
                                widget.callerName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              // Caller name
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Call indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isVideo ? Icons.videocam : Icons.call,
                    color: RegentColors.lightViolet,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RegentConnect',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Accept/Decline buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline button
                    GestureDetector(
                      onTap: _declineCall,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
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
                          const SizedBox(height: 10),
                          const Text(
                            'Decline',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    // Accept button
                    GestureDetector(
                      onTap: _acceptCall,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isVideo ? Icons.videocam : Icons.call,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Accept',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
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
}
