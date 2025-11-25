import '../models/team_member.dart';
import '../services/firebase_service.dart';

class TeamController {
  const TeamController(this._service);

  final FirebaseService _service;

  Future<List<TeamMember>> fetchMembers() => _service.fetchMembers();
}

