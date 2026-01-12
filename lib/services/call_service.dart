import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  // Create a call document
  Future<String> initiateCall({
    required String receiverId,
    required String receiverName,
    required String callerName,
    required bool isVideo,
    String? callerPhoto,
    String? receiverPhoto,
  }) async {
    final callId = '${currentUserId}_${receiverId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Check if receiver is online
    final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
    final isReceiverOnline = receiverDoc.data()?['isOnline'] ?? false;
    
    final callData = {
      'callId': callId,
      'callerId': currentUserId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhoto': receiverPhoto,
      'isVideo': isVideo,
      'status': 'calling', // calling -> ringing -> connecting -> connected -> ended
      'isReceiverOnline': isReceiverOnline,
      'createdAt': FieldValue.serverTimestamp(),
      'connectedAt': null,
      'endedAt': null,
      'duration': 0,
    };

    // Create call document
    await _firestore.collection('calls').doc(callId).set(callData);

    // Create notification for receiver
    await _firestore.collection('users').doc(receiverId).collection('incoming_calls').doc(callId).set({
      ...callData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // If receiver is online, update status to ringing after a short delay
    if (isReceiverOnline) {
      Future.delayed(const Duration(seconds: 2), () {
        updateCallStatus(callId, 'ringing');
      });
    }

    return callId;
  }

  // Update call status
  Future<void> updateCallStatus(String callId, String status) async {
    final updates = <String, dynamic>{'status': status};
    
    if (status == 'connected') {
      updates['connectedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'ended') {
      updates['endedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('calls').doc(callId).update(updates);
  }

  // Listen for incoming calls
  Stream<QuerySnapshot> listenForIncomingCalls() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('incoming_calls')
        .where('status', whereIn: ['calling', 'ringing'])
        .snapshots();
  }

  // Accept call
  Future<void> acceptCall(String callId) async {
    // First set to connecting
    await _firestore.collection('calls').doc(callId).update({
      'status': 'connecting',
    });
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('incoming_calls')
        .doc(callId)
        .update({'status': 'connecting'});

    // Then set to connected after brief delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    await _firestore.collection('calls').doc(callId).update({
      'status': 'connected',
      'connectedAt': FieldValue.serverTimestamp(),
    });
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('incoming_calls')
        .doc(callId)
        .update({'status': 'connected'});
  }

  // Decline call
  Future<void> declineCall(String callId, String callerId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'declined',
      'endedAt': FieldValue.serverTimestamp(),
    });
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('incoming_calls')
        .doc(callId)
        .delete();
  }

  // End call
  Future<void> endCall(String callId, String otherUserId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
    
    // Remove from incoming calls
    await _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('incoming_calls')
        .doc(callId)
        .delete();
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('incoming_calls')
        .doc(callId)
        .delete();
  }

  // Listen to call status
  Stream<DocumentSnapshot> listenToCallStatus(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots();
  }

  // Get active call for current user
  Stream<QuerySnapshot> getActiveCall() {
    return _firestore
        .collection('calls')
        .where('status', whereIn: ['calling', 'ringing', 'connecting', 'connected'])
        .snapshots();
  }

  // Check if user is in a call
  Future<Map<String, dynamic>?> getCurrentCall() async {
    final callerCalls = await _firestore
        .collection('calls')
        .where('callerId', isEqualTo: currentUserId)
        .where('status', whereIn: ['calling', 'ringing', 'connecting', 'connected'])
        .get();

    if (callerCalls.docs.isNotEmpty) {
      return callerCalls.docs.first.data();
    }

    final receiverCalls = await _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', whereIn: ['calling', 'ringing', 'connecting', 'connected'])
        .get();

    if (receiverCalls.docs.isNotEmpty) {
      return receiverCalls.docs.first.data();
    }

    return null;
  }
}
