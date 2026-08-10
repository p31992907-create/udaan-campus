class UserRole {
  static const String superManager = 'super_manager';
  static const String manager = 'manager';
  static const String teacher = 'teacher';
  static const String parent = 'parent';
  static const String student = 'student';

  static const List<String> allRoles = [
    superManager,
    manager,
    teacher,
    parent,
    student,
  ];

  static bool isValid(String role) {
    return allRoles.contains(role.toLowerCase());
  }

  static String normalize(String role) {
    final value = role.toLowerCase();
    return allRoles.contains(value) ? value : student;
  }

  static bool isSuperManager(String role) => normalize(role) == superManager;

  /// Returns true if role is manager or higher (including super_manager)
  static bool isAtLeastManager(String role) {
    final n = normalize(role);
    return n == superManager || n == manager;
  }

  /// Returns true if role is teacher or higher (teacher, manager, super_manager)
  static bool isAtLeastTeacher(String role) {
    final n = normalize(role);
    return n == superManager || n == manager || n == teacher;
  }

  static bool isManager(String role) => normalize(role) == manager;
  static bool isTeacher(String role) => normalize(role) == teacher;
  static bool isParent(String role) => normalize(role) == parent;
  static bool isStudent(String role) => normalize(role) == student;
}
