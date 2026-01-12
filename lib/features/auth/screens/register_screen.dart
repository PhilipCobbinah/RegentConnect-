import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/programs_data.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String? selectedProgram;
  int selectedLevel = 100;
  final List<int> levels = [100, 200, 300, 400];

  String _selectedRole = 'Student'; // Student, Alumni, Lecturer, HoD
  String _selectedStream = 'Morning'; // Morning, Evening, Weekend

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  List<String> get allPrograms {
    List<String> programs = [];
    for (var faculty in universityFaculties) {
      for (var program in faculty.programs) {
        programs.add(program.name);
      }
    }
    return programs;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        program: selectedProgram!,
        level: selectedLevel,
        role: _selectedRole,
        stream: _selectedStream,
      );
      
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RegentColors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: RegentColors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join Regent Connect today',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
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
                ),
                const SizedBox(height: 16),

                // Program Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedProgram,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                  items: allPrograms.map((program) {
                    return DropdownMenuItem(
                      value: program,
                      child: Text(program, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedProgram = value);
                  },
                ),
                const SizedBox(height: 16),

                // Level Dropdown
                DropdownButtonFormField<int>(
                  initialValue: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    prefixIcon: Icon(Icons.stairs),
                    border: OutlineInputBorder(),
                  ),
                  items: levels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text('Level $level'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedLevel = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Role
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Student', 'Alumni', 'Lecturer', 'HoD']
                        .map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRole = value!);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Stream Selection
                const Text(
                  'Stream',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStream,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Morning', 'Evening', 'Weekend']
                        .map((stream) {
                      return DropdownMenuItem(
                        value: stream,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            stream,
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStream = value!);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Password
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
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RegentColors.green,
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
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login'),
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
}
