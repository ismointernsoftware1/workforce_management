import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  const Team({
    required this.id,
    required this.name,
    required this.description,
    required this.memberIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final List<String> memberIds;
  final DateTime createdAt;

  factory Team.fromMap(Map<String, dynamic> data, {String? id}) {
    return Team(
      id: id ?? (data['id'] as String? ?? ''),
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'memberIds': memberIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

