class ProgramData {
  final String name;
  final List<CourseData> courses;
  final List<String>? options;

  const ProgramData({
    required this.name,
    required this.courses,
    this.options,
  });
}

class CourseData {
  final String code;
  final String name;
  final int level; // 100, 200, 300, 400
  final int semester; // 1 or 2

  const CourseData({
    required this.code,
    required this.name,
    required this.level,
    required this.semester,
  });
}

class FacultyData {
  final String name;
  final List<ProgramData> programs;

  const FacultyData({
    required this.name,
    required this.programs,
  });
}

// University Programs Data
final List<FacultyData> universityFaculties = [
  // Faculty of Engineering, Computing and Allied Science (FECAS)
  FacultyData(
    name: 'Faculty of Engineering, Computing and Allied Science (FECAS)',
    programs: [
      ProgramData(
        name: 'BSc. (Hons) Computer Science',
        courses: [], // Will be populated when you provide courses
      ),
      ProgramData(
        name: 'BSc. (Hons) Information Technology',
        courses: [],
      ),
      ProgramData(
        name: 'BEng. (Hons) Applied Electronics and Systems Engineering',
        options: [
          'Computer Engineering',
          'Instrumentation Engineering',
          'Telecommunication Engineering',
        ],
        courses: [],
      ),
    ],
  ),

  // School of Business, Leadership and Legal Studies
  FacultyData(
    name: 'School of Business, Leadership and Legal Studies',
    programs: [
      ProgramData(
        name: 'BSc. (Hons) Accounting and Information Systems',
        courses: [],
      ),
      ProgramData(
        name: 'Bachelor of Business Administration (E-Commerce)',
        courses: [],
      ),
      ProgramData(
        name: 'BSc. (Hons) Management with Computing',
        options: [
          'Marketing Management',
          'Human Resource Management',
        ],
        courses: [],
      ),
    ],
  ),

  // Faculty of Arts and Sciences
  FacultyData(
    name: 'Faculty of Arts and Sciences',
    programs: [
      ProgramData(
        name: 'BSc. (Hons) Psychology',
        courses: [],
      ),
      ProgramData(
        name: 'Bachelor of Theology with Management',
        courses: [],
      ),
    ],
  ),
  FacultyData(
    name: 'Faculty of Science',
    programs: [
      ProgramData(name: 'Information Technology', courses: []),
      ProgramData(name: 'Software Engineering', courses: []),
      ProgramData(name: 'Computer Science', courses: []),
      ProgramData(name: 'Electrical Engineering', courses: []),
      ProgramData(name: 'Mechanical Engineering', courses: []),
      ProgramData(name: 'Civil Engineering', courses: []),
      ProgramData(name: 'Mathematics', courses: []),
      ProgramData(name: 'Physics', courses: []),
      ProgramData(name: 'Chemistry', courses: []),
    ],
  ),
  FacultyData(
    name: 'Faculty of Business',
    programs: [
      ProgramData(name: 'Business Administration', courses: []),
      ProgramData(name: 'Accounting', courses: []),
      ProgramData(name: 'Economics', courses: []),
      ProgramData(name: 'Finance', courses: []),
      ProgramData(name: 'Marketing', courses: []),
      ProgramData(name: 'Human Resources', courses: []),
    ],
  ),
  FacultyData(
    name: 'Faculty of Arts',
    programs: [
      ProgramData(name: 'English', courses: []),
      ProgramData(name: 'History', courses: []),
      ProgramData(name: 'Philosophy', courses: []),
      ProgramData(name: 'Psychology', courses: []),
      ProgramData(name: 'Sociology', courses: []),
    ],
  ),
  FacultyData(
    name: 'Faculty of Law',
    programs: [
      ProgramData(name: 'Law', courses: []),
      ProgramData(name: 'Criminal Justice', courses: []),
    ],
  ),
];
