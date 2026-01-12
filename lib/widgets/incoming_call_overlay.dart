import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../services/call_service.dart';
import '../features/calls/screens/incoming_call_screen.dart';
import 'active_call_overlay.dart';
import '../services/notification_service.dart';

class IncomingCallOverlay extends StatefulWidget {
  final Widget child;

  const IncomingCallOverlay({super.key, required this.child});

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay> {
  final CallService _callService = CallService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _callSubscription;
  bool _isShowingIncomingCall = false;

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    if (_callService.currentUserId.isEmpty) return;

    _callSubscription = _callService.listenForIncomingCalls().listen((snapshot) {
      if (snapshot.docs.isNotEmpty && !_isShowingIncomingCall) {
        final callData = snapshot.docs.first.data() as Map<String, dynamic>;
        // Only show if we're not the caller
        if (callData['callerId'] != _callService.currentUserId) {
          _showIncomingCall(callData);
        }
      }
    });
  }

  void _showIncomingCall(Map<String, dynamic> callData) {
    _isShowingIncomingCall = true;
    
    // Play ringtone
    _notificationService.playRingtone();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(
          callId: callData['callId'],
          callerId: callData['callerId'],
          callerName: callData['callerName'] ?? 'Unknown',
          callerPhoto: callData['callerPhoto'],
          isVideo: callData['isVideo'] ?? false,
        ),
      ),
    ).then((result) {
      _isShowingIncomingCall = false;
      // Stop ringtone when call screen is closed
      _notificationService.stopRingtone();
      
      if (result != null && result is Map && result['minimized'] == true) {
        activeCallOverlayKey.currentState?.setMinimizedCall(callData);
      }
    });
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActiveCallOverlay(
      key: activeCallOverlayKey,
      child: widget.child,
    );
  }
}
