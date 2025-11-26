class MileageService {
  // Standard mileage rate (can be configured)
  static const double defaultMileageRate = 0.65; // per mile (USD)
  
  // Calculate distance between two locations (simplified - would use geocoding API in production)
  double calculateDistance({
    required String startLocation,
    required String endLocation,
  }) {
    // In a real implementation, you would use a geocoding/distance API
    // like Google Maps Distance Matrix API or similar
    // For now, this is a placeholder that returns 0
    // TODO: Implement actual distance calculation using geocoding service
    return 0.0;
  }
  
  // Calculate total mileage reimbursement amount
  double calculateMileageAmount({
    required double distance,
    double? customRate,
  }) {
    final rate = customRate ?? defaultMileageRate;
    return distance * rate;
  }
  
  // Validate mileage entry
  bool isValidMileage({
    required double distance,
    required String startLocation,
    required String endLocation,
  }) {
    if (distance <= 0) return false;
    if (startLocation.isEmpty || endLocation.isEmpty) return false;
    if (distance > 10000) return false; // Sanity check - max 10,000 miles
    
    return true;
  }
}

