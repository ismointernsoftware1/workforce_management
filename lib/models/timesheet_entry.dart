import 'package:cloud_firestore/cloud_firestore.dart';

enum BillableStatus {
  billable,
  nonBillable,
  notSet,
}

class TimesheetEntry {
  const TimesheetEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.teamId,
    required this.date,
    required this.hours,
    this.taskId,
    this.taskTitle,
    this.description,
    this.billableStatus = BillableStatus.notSet,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String teamId;
  final DateTime date;
  final double hours;
  final String? taskId;
  final String? taskTitle;
  final String? description;
  final BillableStatus billableStatus;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TimesheetEntry.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return TimesheetEntry.fromMap(data, id: snap.id);
  }

  factory TimesheetEntry.fromMap(Map<String, dynamic> data, {String? id}) {
    return TimesheetEntry(
      id: id ?? data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      hours: (data['hours'] as num?)?.toDouble() ?? 0.0,
      taskId: (data['taskId'] as String?)?.isNotEmpty == true ? data['taskId'] as String : null,
      taskTitle: (data['taskTitle'] as String?)?.isNotEmpty == true ? data['taskTitle'] as String : null,
      description: (data['description'] as String?)?.isNotEmpty == true ? data['description'] as String : null,
      billableStatus: _billableStatusFrom(data['billableStatus']),
      tags: ((data['tags'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt']?.toString() ?? '')
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp)
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt']?.toString() ?? '')
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'teamId': teamId,
        'date': Timestamp.fromDate(date),
        'hours': hours,
        if (taskId != null) 'taskId': taskId,
        if (taskTitle != null) 'taskTitle': taskTitle,
        if (description != null) 'description': description,
        'billableStatus': billableStatus.name,
        'tags': tags,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };

  TimesheetEntry copyWith({
    String? id,
    String? userId,
    String? userName,
    String? teamId,
    DateTime? date,
    double? hours,
    String? taskId,
    String? taskTitle,
    String? description,
    BillableStatus? billableStatus,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimesheetEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      teamId: teamId ?? this.teamId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      description: description ?? this.description,
      billableStatus: billableStatus ?? this.billableStatus,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

BillableStatus _billableStatusFrom(dynamic raw) {
  if (raw == null) return BillableStatus.notSet;
  final value = raw.toString().toLowerCase();
  return BillableStatus.values.firstWhere(
    (s) => s.name.toLowerCase() == value,
    orElse: () => BillableStatus.notSet,
  );
}

