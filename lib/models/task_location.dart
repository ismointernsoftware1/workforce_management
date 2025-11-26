class TaskLocation {
  const TaskLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.notes,
  });

  final String address;
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? notes;

  factory TaskLocation.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const TaskLocation(
        address: '',
        latitude: 0.0,
        longitude: 0.0,
      );
    }
    return TaskLocation(
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      placeName: data['placeName'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (placeName != null) 'placeName': placeName,
        if (notes != null) 'notes': notes,
      };

  bool get isEmpty => address.isEmpty && latitude == 0.0 && longitude == 0.0;

  TaskLocation copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? placeName,
    String? notes,
  }) {
    return TaskLocation(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeName: placeName ?? this.placeName,
      notes: notes ?? this.notes,
    );
  }
}

