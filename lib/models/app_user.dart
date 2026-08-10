class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? photoUrl;
  final List<String>? assignedClassSections;
  final String? studentClassId;
  final String? studentSection;
  final List<String>? linkedChildren;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.assignedClassSections,
    this.studentClassId,
    this.studentSection,
    this.linkedChildren,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      photoUrl: json['photoUrl'] as String?,
      assignedClassSections: json['assignedClassSections'] != null
          ? List<String>.from(json['assignedClassSections'] as List<dynamic>)
          : null,
      studentClassId: json['studentClassId'] as String?,
      studentSection: json['studentSection'] as String?,
      linkedChildren: json['linkedChildren'] != null
          ? List<String>.from(json['linkedChildren'] as List<dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
    };

    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (assignedClassSections != null) {
      data['assignedClassSections'] = assignedClassSections;
    }
    if (studentClassId != null) data['studentClassId'] = studentClassId;
    if (studentSection != null) data['studentSection'] = studentSection;
    if (linkedChildren != null) data['linkedChildren'] = linkedChildren;

    return data;
  }
}
