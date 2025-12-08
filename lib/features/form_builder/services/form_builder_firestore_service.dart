import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/form_models.dart';

/// Firestore service dedicated to dynamic forms.
///
/// Uses the `forms` collection with documents containing the full form JSON.
class FormBuilderFirestoreService {
  FormBuilderFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _formsCol =>
      _firestore.collection('forms');

  Future<List<FormModel>> getForms({FormType? formType}) async {
    try {
      Query<Map<String, dynamic>> query;
      
      // Filter by form type if specified
      // Note: When using where with orderBy, Firestore requires a composite index
      // To avoid index requirement, we'll filter in memory if needed
      if (formType != null) {
        // Try with orderBy first, but fallback to just where if it fails
        try {
          query = _formsCol.where('formType', isEqualTo: formType.name).orderBy('createdAt', descending: true);
          final snapshot = await query.get();
          return snapshot.docs.map(FormModel.fromSnapshot).toList();
        } catch (e) {
          // If orderBy fails (no index), just use where and sort in memory
          debugPrint('OrderBy failed, using where only: $e');
          final snapshot = await _formsCol.where('formType', isEqualTo: formType.name).get();
          final forms = snapshot.docs.map(FormModel.fromSnapshot).toList();
          // Sort in memory by createdAt descending
          forms.sort((a, b) {
            final aTime = a.createdAt ?? DateTime(1970);
            final bTime = b.createdAt ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
          return forms;
        }
      } else {
        query = _formsCol.orderBy('createdAt', descending: true);
        final snapshot = await query.get();
        return snapshot.docs.map(FormModel.fromSnapshot).toList();
      }
    } catch (e) {
      debugPrint('Error loading forms: $e');
      // Fallback: get all forms and filter in memory
      final snapshot = await _formsCol.get();
      var forms = snapshot.docs.map(FormModel.fromSnapshot).toList();
      if (formType != null) {
        forms = forms.where((f) => f.formType == formType).toList();
      }
      // Sort by createdAt descending
      forms.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(1970);
        final bTime = b.createdAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      return forms;
    }
  }

  Future<FormModel?> getForm(String formId) async {
    final snap = await _formsCol.doc(formId).get();
    if (!snap.exists) return null;
    return FormModel.fromSnapshot(snap);
  }

  Future<String> createForm(FormModel form) async {
    final docRef = await _formsCol.add(form.toMapForFirestore());
    return docRef.id;
  }

  Future<void> updateForm(FormModel form) async {
    await _formsCol.doc(form.id).update(form.toMapForFirestore());
  }

  Future<void> deleteForm(String formId) async {
    await _formsCol.doc(formId).delete();
  }
}


