import '../models/team_member.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class TeamController {
  const TeamController(this._service);

  final FirebaseService _service;

  Future<List<UserModel>> fetchUsers() => _service.fetchUsers();

  Future<List<TeamMember>> fetchMembers() => _service.fetchMembers();

  Future<void> addUser(UserModel user, {String? password, String? roleId}) => 
      _service.addUser(user, password: password, roleId: roleId);

  Future<void> updateUser(UserModel user) => _service.updateUser(user);

  Future<void> deleteUser(String userId) => _service.deleteUser(userId);

  Future<List<Team>> fetchTeams() => _service.fetchTeams();

  Future<void> createTeam(Team team) => _service.createTeam(team);

  Future<void> updateTeamMembers(
          String teamId, List<String> memberIds) =>
      _service.updateTeamMembers(teamId, memberIds);

  Future<void> updateTeam(Team team) => _service.updateTeam(team);

  Future<void> deleteTeam(String teamId) => _service.deleteTeam(teamId);
}

