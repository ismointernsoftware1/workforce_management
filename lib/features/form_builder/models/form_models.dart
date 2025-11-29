import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of fields supported by the dynamic form builder.
enum FormFieldType {
  text,
  number,
  email,
  dropdown,
  checkbox,
  radio,
  date,
  textarea,
  fileUpload,
  sectionTitle,
  divider,
}

/// Model representing a single field in a dynamic form section.
class FormFieldModel {
  FormFieldModel({
    required this.id,
    required this.type,
    this.label = '',
    this.placeholder = '',
    this.required = false,
    this.helpText = '',
    List<String>? options,
  }) : options = options ?? <String>[];

  final String id;
  final FormFieldType type;
  String label;
  String placeholder;
  bool required;
  String helpText;
  List<String> options;

  FormFieldModel copy() {
    return FormFieldModel(
      id: id,
      type: type,
      label: label,
      placeholder: placeholder,
      required: required,
      helpText: helpText,
      options: List<String>.from(options),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'label': label,
      'placeholder': placeholder,
      'required': required,
      'helpText': helpText,
      'options': options,
    };
  }

  factory FormFieldModel.fromMap(Map<String, dynamic> map) {
    return FormFieldModel(
      id: map['id'] as String? ?? '',
      type: FormFieldType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => FormFieldType.text,
      ),
      label: map['label'] as String? ?? '',
      placeholder: map['placeholder'] as String? ?? '',
      required: map['required'] as bool? ?? false,
      helpText: map['helpText'] as String? ?? '',
      options: (map['options'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Model representing a logical section in a dynamic form.
class FormSectionModel {
  FormSectionModel({
    required this.id,
    required this.title,
    List<FormFieldModel>? fields,
  }) : fields = fields ?? <FormFieldModel>[];

  final String id;
  String title;
  List<FormFieldModel> fields;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'fields': fields.map((f) => f.toMap()).toList(),
    };
  }

  factory FormSectionModel.fromMap(Map<String, dynamic> map) {
    return FormSectionModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      fields: (map['fields'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => FormFieldModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Root model representing a single dynamic form document.
class FormModel {
  FormModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    List<FormSectionModel>? sections,
  }) : sections = sections ?? <FormSectionModel>[];

  final String id;
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<FormSectionModel> sections;

  Map<String, dynamic> toMapForFirestore() {
    return <String, dynamic>{
      'name': name,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'sections': sections.map((s) => s.toMap()).toList(),
    };
  }

  factory FormModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return FormModel(
      id: snap.id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      sections: (data['sections'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => FormSectionModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}


