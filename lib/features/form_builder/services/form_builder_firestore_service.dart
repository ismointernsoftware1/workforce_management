import 'package:cloud_firestore/cloud_firestore.dart';

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
    Query<Map<String, dynamic>> query;
    
    // Filter by form type if specified - must apply where before orderBy
    if (formType != null) {
      query = _formsCol.where('formType', isEqualTo: formType.name).orderBy('createdAt', descending: true);
    } else {
      query = _formsCol.orderBy('createdAt', descending: true);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map(FormModel.fromSnapshot).toList();
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


