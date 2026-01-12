import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/main_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/chat/screens/create_group_screen.dart';
import 'features/p_questions/screens/past_questions_screen.dart';
import 'features/ai_bot/screens/regent_ai_screen.dart';
import 'features/status/screens/status_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/users/screens/users_screen.dart';
import 'services/auth_service.dart';
import 'features/broadcast/screens/broadcast_screen.dart';
import 'widgets/incoming_call_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Regent Connect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const IncomingCallOverlay(
            child: AuthWrapper(),
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const MainScreen(),
            '/chat': (context) => const ChatScreen(),
            '/users': (context) => const UsersScreen(),
            '/broadcast': (context) => const BroadcastScreen(),
            '/create-group': (context) => const CreateGroupScreen(),
            '/past-questions': (context) => const PastQuestionsScreen(),
            '/ai-bot': (context) => const RegentAIScreen(),
            '/status': (context) => const StatusScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          return const MainScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}

