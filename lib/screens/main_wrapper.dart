import 'package:flutter/material.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/p_questions/screens/questions_screen.dart';
import '../features/ai_bot/screens/regent_ai_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const ChatListScreen(),
    const PastQuestionsScreen(),
    const RegentAIScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Past Qs"),
          BottomNavigationBarItem(icon: Icon(Icons.android), label: "RegentAI"),
        ],
      ),
    );
  }
}
