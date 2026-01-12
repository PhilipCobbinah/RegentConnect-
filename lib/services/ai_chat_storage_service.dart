import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AIChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageData;
  final String? audioUrl;
  final int? audioDuration;

  AIChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.imageData,
    this.audioUrl,
    this.audioDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'imageData': imageData != null ? base64Encode(imageData!) : null,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
    };
  }

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      content: json['content'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      imageData: json['imageData'] != null ? base64Decode(json['imageData']) : null,
      audioUrl: json['audioUrl'],
      audioDuration: json['audioDuration'],
    );
  }
}

class AIChatStorageService {
  static const String _storageKey = 'regent_ai_chat_history';

  // Save messages to local storage
  Future<void> saveMessages(List<AIChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = messages.map((m) => m.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving AI chat messages: $e');
    }
  }

  // Load messages from local storage
  Future<List<AIChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => AIChatMessage.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading AI chat messages: $e');
      return [];
    }
  }

  // Clear chat history
  Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing AI chat messages: $e');
    }
  }
}
