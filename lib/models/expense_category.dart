class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.icon,
    this.color,
    this.maxAmount,
    this.requiresApproval,
  });

  final String id;
  final String name;
  final String code; // e.g., 'TRAVEL', 'MEALS', 'OFFICE_SUPPLIES'
  final String? description;
  final String? icon; // Icon identifier
  final String? color; // Hex color code
  final double? maxAmount; // Maximum amount allowed without additional approval
  final bool? requiresApproval; // Whether this category requires approval

  factory ExpenseCategory.fromMap(Map<String, dynamic> data, {String? id}) {
    return ExpenseCategory(
      id: id ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
      description: data['description'] as String?,
      icon: data['icon'] as String?,
      color: data['color'] as String?,
      maxAmount: (data['maxAmount'] as num?)?.toDouble(),
      requiresApproval: data['requiresApproval'] as bool?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'code': code,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        if (maxAmount != null) 'maxAmount': maxAmount,
        if (requiresApproval != null) 'requiresApproval': requiresApproval,
      };

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? icon,
    String? color,
    double? maxAmount,
    bool? requiresApproval,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      maxAmount: maxAmount ?? this.maxAmount,
      requiresApproval: requiresApproval ?? this.requiresApproval,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

