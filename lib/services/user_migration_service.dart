import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class UserMigrationService {
  UserMigrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  FirebaseAuth? _secondaryAuth;

  /// Migrate existing users to have Firebase Auth accounts
  /// Returns a list of results for each user
  Future<List<MigrationResult>> migrateUsers({
    String defaultPassword = 'TempPassword123!',
    bool updatePassword = false,
  }) async {
    final results = <MigrationResult>[];

    try {
      // Get all users from Firestore
      final snapshot = await _firestore.collection('users').get();
      print('📋 Found ${snapshot.docs.length} users to migrate');

      for (final doc in snapshot.docs) {
        try {
          final userData = doc.data();
          final email = userData['email'] as String? ?? '';
          final name = userData['name'] as String? ?? 'User';
          final userId = doc.id;

          if (email.isEmpty) {
            results.add(MigrationResult(
              userId: userId,
              email: email,
              name: name,
              success: false,
              message: 'Email is missing',
            ));
            continue;
          }

            // Check if user already has Firebase Auth account
          try {
            final existingUser = await _auth.fetchSignInMethodsForEmail(email);
            if (existingUser.isNotEmpty) {
              // User already has Auth account. We cannot fetch their UID from client SDK,
              // so we ask admins to migrate those users manually.
              results.add(MigrationResult(
                userId: userId,
                email: email,
                name: name,
                success: true,
                message:
                    'Auth account already exists. Please ensure Firestore doc ID matches the Auth UID manually.',
                skipped: true,
              ));
              continue;
            }
          } catch (e) {
            // Email not found in Auth, continue to create
            print('User $email not in Auth, will create: $e');
          }

          // Create Firebase Auth account
          try {
            final secondaryAuth = await _getSecondaryAuth();
            final credential = await secondaryAuth.createUserWithEmailAndPassword(
              email: email,
              password: defaultPassword,
            );

            final authUid = credential.user!.uid;

            await credential.user?.updateDisplayName(name);

            // If Firestore doc ID doesn't match Auth UID, migrate the document
            if (userId != authUid) {
              await _migrateDocument(userId, authUid, userData);
            }

            // Update additional fields if needed
            final updateData = <String, dynamic>{};
            if (userData['status'] != null) {
              updateData['status'] = userData['status'];
            }
            if (userData['joinDate'] != null) {
              updateData['joinDate'] = userData['joinDate'];
            }
            if (userData['manager'] != null) {
              updateData['manager'] = userData['manager'];
            }
            if (userData['team'] != null) {
              updateData['team'] = userData['team'];
            }
            if (userData['accountType'] != null) {
              updateData['accountType'] = userData['accountType'];
            }
            if (userData['userStatus'] != null) {
              updateData['userStatus'] = userData['userStatus'];
            }

            if (updateData.isNotEmpty) {
              await _firestore.collection('users').doc(authUid).update(updateData);
            }

            results.add(
              MigrationResult(
              userId: userId,
              email: email,
              name: name,
              success: true,
              message: 'Auth account created successfully',
              newUserId: authUid,
              ),
            );

            // Sign out from secondary auth to avoid keeping session
            await secondaryAuth.signOut();

            print('✅ Created Auth account for $email (${authUid})');
          } catch (e) {
            results.add(MigrationResult(
              userId: userId,
              email: email,
              name: name,
              success: false,
              message: 'Failed to create Auth account: ${e.toString()}',
            ));
            print('❌ Failed to create Auth account for $email: $e');
          }
        } catch (e) {
          results.add(MigrationResult(
            userId: doc.id,
            email: '',
            name: 'Unknown',
            success: false,
            message: 'Error processing user: ${e.toString()}',
          ));
        }
      }

      return results;
    } catch (e) {
      print('❌ Migration error: $e');
      rethrow;
    }
  }

  /// Migrate Firestore document from old ID to new Auth UID
  Future<void> _migrateDocument(
    String oldId,
    String newId,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Create new document with Auth UID
      await _firestore.collection('users').doc(newId).set(userData);
      
      // Delete old document
      await _firestore.collection('users').doc(oldId).delete();
      
      print('📦 Migrated document from $oldId to $newId');
    } catch (e) {
      print('❌ Error migrating document: $e');
      rethrow;
    }
  }

  /// Get migration status - count of users with/without Auth accounts
  Future<MigrationStatus> getMigrationStatus() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      int withAuth = 0;
      int withoutAuth = 0;
      final usersNeedingMigration = <String>[];

      for (final doc in snapshot.docs) {
        final email = doc.data()['email'] as String? ?? '';
        if (email.isEmpty) {
          withoutAuth++;
          continue;
        }

        try {
          final methods = await _auth.fetchSignInMethodsForEmail(email);
          if (methods.isNotEmpty) {
            withAuth++;
          } else {
            withoutAuth++;
            usersNeedingMigration.add(email);
          }
        } catch (e) {
          withoutAuth++;
          usersNeedingMigration.add(email);
        }
      }

      return MigrationStatus(
        totalUsers: snapshot.docs.length,
        withAuthAccounts: withAuth,
        withoutAuthAccounts: withoutAuth,
        usersNeedingMigration: usersNeedingMigration,
      );
    } catch (e) {
      print('Error getting migration status: $e');
      return MigrationStatus(
        totalUsers: 0,
        withAuthAccounts: 0,
        withoutAuthAccounts: 0,
        usersNeedingMigration: [],
      );
    }
  }

  Future<FirebaseAuth> _getSecondaryAuth() async {
    if (_secondaryAuth != null) return _secondaryAuth!;

    try {
      final app = Firebase.app('user_migration');
      _secondaryAuth = FirebaseAuth.instanceFor(app: app);
      return _secondaryAuth!;
    } catch (_) {
      final app = await Firebase.initializeApp(
        name: 'user_migration',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _secondaryAuth = FirebaseAuth.instanceFor(app: app);
      return _secondaryAuth!;
    }
  }
}

class MigrationResult {
  MigrationResult({
    required this.userId,
    required this.email,
    required this.name,
    required this.success,
    required this.message,
    this.newUserId,
    this.skipped = false,
  });

  final String userId;
  final String email;
  final String name;
  final bool success;
  final String message;
  final String? newUserId;
  final bool skipped;
}

class MigrationStatus {
  MigrationStatus({
    required this.totalUsers,
    required this.withAuthAccounts,
    required this.withoutAuthAccounts,
    required this.usersNeedingMigration,
  });

  final int totalUsers;
  final int withAuthAccounts;
  final int withoutAuthAccounts;
  final List<String> usersNeedingMigration;
}

// Placeholder for UserRecord - in production you'd use Firebase Admin SDK
class UserRecord {
  UserRecord({required this.uid, required this.email});
  final String uid;
  final String email;
}

