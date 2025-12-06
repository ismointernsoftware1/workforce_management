class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.status,
    this.manager,
    this.team,
    this.userStatus,
    this.photoUrl,
    this.about,
  });

  final String id;
  final String name;
  final String role;
  final String email;
  final String status; // Active, On leave, etc.
  final String? manager;
  final String? team;
  final String? userStatus;
  final String? photoUrl;
  final String? about;

  factory UserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return UserModel(
      id: id ?? (data['id'] as String? ?? ''),
      name: (data['name'] as String? ?? '').trim(),
      role: (data['role'] as String? ?? 'Employee').trim(),
      email: (data['email'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'Active').trim(),
      manager: data['manager'] as String?,
      team: data['team'] as String?,
      userStatus: data['userStatus'] as String?,
      photoUrl: data['photoUrl'] as String?,
      about: data['about'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'email': email,
        'status': status,
        'manager': manager,
        'team': team,
        'userStatus': userStatus,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (about != null) 'about': about,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? role,
    String? email,
    String? status,
    String? manager,
    String? team,
    String? userStatus,
    String? photoUrl,
    String? about,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      status: status ?? this.status,
      manager: manager ?? this.manager,
      team: team ?? this.team,
      userStatus: userStatus ?? this.userStatus,
      photoUrl: photoUrl ?? this.photoUrl,
      about: about ?? this.about,
    );
  }
}

