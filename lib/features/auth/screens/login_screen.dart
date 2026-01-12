import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberEmail = false;
  List<String> _savedEmails = [];

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
  }

  Future<void> _loadSavedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emails = prefs.getStringList('saved_emails') ?? [];
      final remember = prefs.getBool('remember_email') ?? false;
      final lastEmail = prefs.getString('last_email') ?? '';
      
      setState(() {
        _savedEmails = emails;
        _rememberEmail = remember;
        if (remember && lastEmail.isNotEmpty) {
          _emailController.text = lastEmail;
        }
      });
    } catch (e) {
      print('Error loading saved emails: $e');
    }
  }

  Future<void> _saveEmail(String email) async {
    if (!_rememberEmail || email.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Add to saved emails list (max 5)
      if (!_savedEmails.contains(email)) {
        _savedEmails.insert(0, email);
        if (_savedEmails.length > 5) {
          _savedEmails = _savedEmails.sublist(0, 5);
        }
      } else {
        // Move to top if already exists
        _savedEmails.remove(email);
        _savedEmails.insert(0, email);
      }
      
      await prefs.setStringList('saved_emails', _savedEmails);
      await prefs.setString('last_email', email);
      await prefs.setBool('remember_email', true);
    } catch (e) {
      print('Error saving email: $e');
    }
  }

  Future<void> _clearSavedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_emails');
      await prefs.remove('last_email');
      await prefs.setBool('remember_email', false);
      setState(() {
        _savedEmails = [];
        _rememberEmail = false;
      });
    } catch (e) {
      print('Error clearing emails: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Save email if remember is enabled
      await _saveEmail(_emailController.text.trim());
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo/Header
                const Icon(
                  Icons.school,
                  size: 80,
                  color: RegentColors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Regent Connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: RegentColors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),

                // Email Field with Autocomplete
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty || _savedEmails.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _savedEmails.where((email) {
                      return email.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (String selection) {
                    _emailController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync with our controller
                    controller.text = _emailController.text;
                    controller.addListener(() {
                      _emailController.text = controller.text;
                    });
                    
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                        suffixIcon: _savedEmails.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.arrow_drop_down),
                                onPressed: () {
                                  // Show dropdown
                                  focusNode.requestFocus();
                                },
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 48,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final email = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.email_outlined),
                                title: Text(email),
                                dense: true,
                                onTap: () => onSelected(email),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    setState(() {
                                      _savedEmails.remove(email);
                                    });
                                    await prefs.setStringList('saved_emails', _savedEmails);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Remember Email & Forgot Password Row
                Row(
                  children: [
                    // Remember Email Toggle
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberEmail,
                              onChanged: (value) async {
                                setState(() => _rememberEmail = value ?? false);
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('remember_email', value ?? false);
                                if (value == false) {
                                  await _clearSavedEmails();
                                }
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final newValue = !_rememberEmail;
                              setState(() => _rememberEmail = newValue);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('remember_email', newValue);
                              if (!newValue) {
                                await _clearSavedEmails();
                              }
                            },
                            child: const Text(
                              'Remember Email',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Forgot Password
                    TextButton(
                      onPressed: () => _showForgotPasswordDialog(),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RegentColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your email')),
                );
                return;
              }
              
              try {
                await _authService.resetPassword(emailController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent! Check your inbox.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}
