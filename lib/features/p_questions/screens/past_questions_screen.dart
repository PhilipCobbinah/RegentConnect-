import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/programs_data.dart';
import '../../../models/past_question_model.dart';
import '../../../services/past_questions_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/theme_provider.dart';
import 'upload_past_question_screen.dart';
import 'view_past_questions_screen.dart';
import '../../../widgets/regent_ai_fab.dart';

class PastQuestionsScreen extends StatefulWidget {
  const PastQuestionsScreen({super.key});

  @override
  State<PastQuestionsScreen> createState() => _PastQuestionsScreenState();
}

class _PastQuestionsScreenState extends State<PastQuestionsScreen> {
  FacultyData? selectedFaculty;
  ProgramData? selectedProgram;
  String? selectedOption;
  int? selectedLevel;
  int? selectedSemester;

  final List<int> levels = [100, 200, 300, 400];
  final List<int> semesters = [1, 2];
  final List<int> years = List.generate(11, (index) => 2015 + index); // 2015-2025

  void _resetBelow(String level) {
    setState(() {
      switch (level) {
        case 'faculty':
          selectedProgram = null;
          selectedOption = null;
          selectedLevel = null;
          selectedSemester = null;
          break;
        case 'program':
          selectedOption = null;
          selectedLevel = null;
          selectedSemester = null;
          break;
        case 'option':
          selectedLevel = null;
          selectedSemester = null;
          break;
        case 'level':
          selectedSemester = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: RegentColors.dmBackground,
      appBar: AppBar(
        backgroundColor: RegentColors.dmSurface,
        elevation: 0,
        title: const Text('Past Questions', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Existing scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(),
                const SizedBox(height: 24),

                // Faculty Dropdown
                _buildDropdownCard(
                  title: 'Select Faculty',
                  icon: Icons.school,
                  child: DropdownButtonFormField<FacultyData>(
                    value: selectedFaculty,
                    isExpanded: true,
                    dropdownColor: RegentColors.dmCard,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: RegentColors.violet, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: RegentColors.dmCard,
                    ),
                    hint: const Text('Choose your faculty', style: TextStyle(color: Colors.white54)),
                    items: universityFaculties.map((faculty) {
                      return DropdownMenuItem(
                        value: faculty,
                        child: Text(faculty.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _resetBelow('faculty');
                      setState(() => selectedFaculty = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Program Dropdown
                if (selectedFaculty != null) ...[
                  _buildDropdownCard(
                    title: 'Select Program',
                    icon: Icons.book,
                    child: DropdownButtonFormField<ProgramData>(
                      value: selectedProgram,
                      isExpanded: true,
                      dropdownColor: RegentColors.dmCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: RegentColors.violet, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: RegentColors.dmCard,
                      ),
                      hint: const Text('Choose your program', style: TextStyle(color: Colors.white54)),
                      items: selectedFaculty!.programs.map((program) {
                        return DropdownMenuItem(
                          value: program,
                          child: Text(program.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _resetBelow('program');
                        setState(() => selectedProgram = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Option Dropdown (if program has options)
                if (selectedProgram != null && selectedProgram!.options != null) ...[
                  _buildDropdownCard(
                    title: 'Select Option',
                    icon: Icons.category,
                    child: DropdownButtonFormField<String>(
                      value: selectedOption,
                      isExpanded: true,
                      dropdownColor: RegentColors.dmCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: RegentColors.violet, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: RegentColors.dmCard,
                      ),
                      hint: const Text('Choose your option', style: TextStyle(color: Colors.white54)),
                      items: selectedProgram!.options!.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _resetBelow('option');
                        setState(() => selectedOption = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Level Dropdown
                if (selectedProgram != null &&
                    (selectedProgram!.options == null || selectedOption != null)) ...[
                  _buildDropdownCard(
                    title: 'Select Level',
                    icon: Icons.stairs,
                    child: DropdownButtonFormField<int>(
                      value: selectedLevel,
                      dropdownColor: RegentColors.dmCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: RegentColors.violet, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: RegentColors.dmCard,
                      ),
                      hint: const Text('Choose your level', style: TextStyle(color: Colors.white54)),
                      items: levels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text('Level $level'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _resetBelow('level');
                        setState(() => selectedLevel = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Semester Dropdown
                if (selectedLevel != null) ...[
                  _buildDropdownCard(
                    title: 'Select Semester',
                    icon: Icons.calendar_today,
                    child: DropdownButtonFormField<int>(
                      value: selectedSemester,
                      dropdownColor: RegentColors.dmCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: RegentColors.violet.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: RegentColors.violet, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: RegentColors.dmCard,
                      ),
                      hint: const Text('Choose semester', style: TextStyle(color: Colors.white54)),
                      items: semesters.map((semester) {
                        return DropdownMenuItem(
                          value: semester,
                          child: Text('Semester $semester'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedSemester = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Buttons
                if (selectedSemester != null) ...[
                  _buildSelectionSummary(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
          // Regent AI Floating Button - with proper bottomOffset like home screen
          const RegentAICrystalFab(bottomOffset: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RegentColors.violet, RegentColors.darkViolet],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: RegentColors.violet.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.library_books, size: 48, color: Colors.white),
          SizedBox(height: 12),
          Text(
            'Past Questions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload, view, and download past questions\nYears: 2015 - 2025',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: RegentColors.dmSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RegentColors.violet.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: RegentColors.violet, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary() {
    return Container(
      decoration: BoxDecoration(
        color: RegentColors.violet.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RegentColors.violet.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: RegentColors.violet),
                const SizedBox(width: 8),
                Text(
                  'Your Selection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: RegentColors.violet,
                  ),
                ),
              ],
            ),
            Divider(color: RegentColors.violet.withOpacity(0.3)),
            _buildSummaryRow('Faculty', selectedFaculty?.name ?? ''),
            _buildSummaryRow('Program', selectedProgram?.name ?? ''),
            if (selectedOption != null)
              _buildSummaryRow('Option', selectedOption!),
            _buildSummaryRow('Level', 'Level $selectedLevel'),
            _buildSummaryRow('Semester', 'Semester $selectedSemester'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Upload Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToUpload(),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Past Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RegentColors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // View Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToView(),
            icon: const Icon(Icons.visibility),
            label: const Text('View Past Questions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RegentColors.violet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Download Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToView(),
            icon: const Icon(Icons.download),
            label: const Text('Download Past Questions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RegentColors.violet,
              side: const BorderSide(color: RegentColors.violet),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadPastQuestionScreen(
          facultyName: selectedFaculty!.name,
          programName: selectedProgram!.name,
          option: selectedOption,
          level: selectedLevel!,
          semester: selectedSemester!,
        ),
      ),
    );
  }

  void _navigateToView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPastQuestionsScreen(
          facultyName: selectedFaculty!.name,
          programName: selectedProgram!.name,
          option: selectedOption,
          level: selectedLevel!,
          semester: selectedSemester!,
        ),
      ),
    );
  }

  void _showMyUploads(BuildContext context) {
    final authService = AuthService();
    final userId = authService.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to view your uploads')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyUploadsScreen(userId: userId),
      ),
    );
  }
}

// My Uploads Screen - also update to violet/black theme
class MyUploadsScreen extends StatelessWidget {
  final String userId;

  const MyUploadsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final service = PastQuestionsService();

    return Scaffold(
      backgroundColor: RegentColors.dmBackground,
      appBar: AppBar(
        backgroundColor: RegentColors.dmSurface,
        title: const Text('My Uploads', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<PastQuestionModel>>(
        stream: service.getUserUploadedQuestions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: RegentColors.violet));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, size: 64, color: RegentColors.violet.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No uploads yet', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text(
                    'Your uploaded past questions will appear here',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          final questions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return _buildUploadCard(context, question, service);
            },
          );
        },
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context, PastQuestionModel question, PastQuestionsService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RegentColors.dmSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RegentColors.violet.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getFileIcon(question.fileType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.courseName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '${question.courseCode} • ${question.year}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: RegentColors.dmCard,
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: RegentColors.dmSurface,
                          title: const Text('Delete Upload', style: TextStyle(color: Colors.white)),
                          content: const Text('Are you sure you want to delete this past question?', style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await service.deletePastQuestion(question.id, question.fileUrl);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Past question deleted')),
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: RegentColors.violet.withOpacity(0.2)),
            Text(
              'Level ${question.level} • Semester ${question.semester}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              question.programName,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.download, size: 14, color: RegentColors.violet),
                const SizedBox(width: 4),
                Text(
                  '${question.downloadCount} downloads',
                  style: TextStyle(fontSize: 12, color: RegentColors.lightViolet),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFileIcon(String fileType) {
    IconData icon;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = RegentColors.violet;
        break;
      case 'png':
      case 'jpg':
      case 'jpeg':
        icon = Icons.image;
        color = RegentColors.green;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 40);
  }
}
