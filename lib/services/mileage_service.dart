import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class MileageService {
  MileageService({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  // Standard mileage rate (can be configured)
  static const double defaultMileageRate = 0.65; // per mile (USD)
  
  // Calculate distance between two locations using geocoding
  Future<Map<String, dynamic>> calculateDistance({
    required String startLocation,
    required String endLocation,
  }) async {
    try {
      // Geocode both addresses to get coordinates
      final startCoords = await _locationService.geocodeAddress(startLocation);
      final endCoords = await _locationService.geocodeAddress(endLocation);

      if (startCoords.isEmpty) {
        return {
          'success': false,
          'error': 'Could not find coordinates for start location: "$startLocation". Please try a more specific address (e.g., "Mumbai, India" or "Delhi, India").',
          'distance': null,
        };
      }

      if (endCoords.isEmpty) {
        return {
          'success': false,
          'error': 'Could not find coordinates for end location: "$endLocation". Please try a more specific address (e.g., "Mumbai, India" or "Delhi, India").',
          'distance': null,
        };
      }

      final startLat = startCoords[0]['latitude'] as double;
      final startLng = startCoords[0]['longitude'] as double;
      final endLat = endCoords[0]['latitude'] as double;
      final endLng = endCoords[0]['longitude'] as double;

      // Calculate distance in meters using Haversine formula
      final distanceInMeters = Geolocator.distanceBetween(
        startLat,
        startLng,
        endLat,
        endLng,
      );

      // Convert meters to miles (1 mile = 1609.34 meters)
      final distanceInMiles = distanceInMeters / 1609.34;

      return {
        'success': true,
        'distance': distanceInMiles,
        'error': null,
      };
    } catch (e) {
      // If geocoding fails, return error details
      return {
        'success': false,
        'error': 'Geocoding error: ${e.toString()}. Please try entering more specific addresses or enter the distance manually.',
        'distance': null,
      };
    }
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

  // Get distance unit (miles or kilometers)
  String getDistanceUnit({bool useMetric = false}) {
    return useMetric ? 'km' : 'miles';
  }

  // Convert miles to kilometers
  double milesToKilometers(double miles) {
    return miles * 1.60934;
  }

  // Convert kilometers to miles
  double kilometersToMiles(double kilometers) {
    return kilometers / 1.60934;
  }
}

