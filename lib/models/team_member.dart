class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.isOnline,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final bool isOnline;

  factory TeamMember.fromMap(Map<String, dynamic> data, {String? id}) {
    return TeamMember(
      id: id ?? (data['id'] as String? ?? ''),
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      department: data['department'] as String? ?? '',
      isOnline: data['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'department': department,
        'isOnline': isOnline,
      };
}

