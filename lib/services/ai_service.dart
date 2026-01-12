import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  late GenerativeModel _model;
  late ChatSession _chatSession;

  AIService() {
    // Initialize Gemini API with your API key
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: 'AIzaSyB58cacHyqUZU1tjqwkfguFUre_iGtP4qw',
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    
    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    try {
      // Add context to the message for better responses
      final contextualMessage = '''You are Regent AI, an intelligent academic assistant for Regent University students. 
You have access to real-time information and can provide accurate answers to academic questions.

When answering questions:
1. Provide accurate, detailed information
2. Cite sources when relevant
3. Explain concepts clearly for students
4. Offer practical examples
5. Suggest further learning resources

Be helpful, friendly, and educational in your responses.

User Question: $message''';

      final response = await _chatSession.sendMessage(
        Content.text(contextualMessage),
      );

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'Sorry, I could not process your question. Please try again.';
      }
    } catch (e) {
      return 'Error: Unable to get response. Please check your API key and internet connection. Error details: $e';
    }
  }

  Future<String> analyzeImage(Uint8List imageBytes, String mimeType) async {
    try {
      final response = await _chatSession.sendMessage(
        Content.multi([
          TextPart('''You are Regent AI, an academic assistant. Analyze this image and provide a detailed explanation. 
If it contains a math problem, solve it step by step with clear working. 
If it's a diagram or chart, explain what it shows and provide insights.
Be educational and helpful in your response.'''),
          DataPart(mimeType, imageBytes),
        ]),
      );

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'Sorry, I could not analyze the image. Please try again.';
      }
    } catch (e) {
      return 'Error analyzing image: $e';
    }
  }

  void resetChat() {
    _chatSession = _model.startChat();
  }

  List<Content> getChatHistory() {
    return _chatSession.history.toList();
  }

  void clearChatHistory() {
    _chatSession = _model.startChat();
  }
}
