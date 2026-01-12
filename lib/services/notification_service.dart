import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMuted = false;

  // Play message received sound
  Future<void> playMessageSound() async {
    if (_isMuted) return;
    
    try {
      // Use a built-in system sound or asset
      if (kIsWeb) {
        // For web, use a URL or asset
        await _audioPlayer.play(AssetSource('sounds/message_received.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/message_received.mp3'));
      }
    } catch (e) {
      // Fallback: try to play a simple beep using UrlSource
      try {
        await _audioPlayer.play(UrlSource(
          'https://notificationsounds.com/storage/sounds/file-sounds-1150-pristine.mp3'
        ));
      } catch (e2) {
        debugPrint('Could not play notification sound: $e2');
      }
    }
  }

  // Play message sent sound
  Future<void> playMessageSentSound() async {
    if (_isMuted) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/message_sent.mp3'));
    } catch (e) {
      debugPrint('Could not play sent sound: $e');
    }
  }

  // Play call ringtone
  Future<void> playRingtone() async {
    if (_isMuted) return;
    
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    } catch (e) {
      try {
        await _audioPlayer.play(UrlSource(
          'https://notificationsounds.com/storage/sounds/file-sounds-1085-definite.mp3'
        ));
      } catch (e2) {
        debugPrint('Could not play ringtone: $e2');
      }
    }
  }

  // Stop ringtone
  Future<void> stopRingtone() async {
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.release);
  }

  // Play status view sound
  Future<void> playStatusViewSound() async {
    if (_isMuted) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/status_view.mp3'));
    } catch (e) {
      debugPrint('Could not play status sound: $e');
    }
  }

  // Mute/unmute notifications
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  bool get isMuted => _isMuted;

  // Dispose
  void dispose() {
    _audioPlayer.dispose();
  }
}
