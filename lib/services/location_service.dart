import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' show locationFromAddress, placemarkFromCoordinates;

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return 'Unknown location';
      }

      final place = placemarks[0];
      final addressParts = <String>[];
      
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }

      return addressParts.isEmpty ? 'Unknown location' : addressParts.join(', ');
    } catch (e) {
      return 'Unable to get address';
    }
  }

  Future<Map<String, dynamic>> getLocationDetails({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return {
          'address': 'Unknown location',
          'placeName': null,
        };
      }

      final place = placemarks[0];
      final addressParts = <String>[];
      
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }

      return {
        'address': addressParts.isEmpty ? 'Unknown location' : addressParts.join(', '),
        'placeName': place.name?.isNotEmpty == true ? place.name : place.locality,
      };
    } catch (e) {
      return {
        'address': 'Unable to get address',
        'placeName': null,
      };
    }
  }

  Future<List<Map<String, dynamic>>> geocodeAddress(String address) async {
    // Clean the address: remove quotes, extra spaces, and normalize
    String cleanAddress = address
        .trim()
        .replaceAll('"', '') // Remove double quotes
        .replaceAll("'", '') // Remove single quotes
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();
    
    if (cleanAddress.isEmpty) {
      return [];
    }
    
    // Try to improve address format for better geocoding results
    String formattedAddress = cleanAddress;
    
    // If address doesn't contain country, try adding common country names
    // This helps with city names like "mumbai" or "delhi"
    final lowerAddress = formattedAddress.toLowerCase();
    if (!lowerAddress.contains('india') &&
        !lowerAddress.contains('usa') &&
        !lowerAddress.contains('united states') &&
        !lowerAddress.contains('united kingdom') &&
        !lowerAddress.contains('uk')) {
      // For common Indian cities, add India
      final indianCities = ['mumbai', 'delhi', 'bangalore', 'chennai', 'kolkata', 
                           'hyderabad', 'pune', 'ahmedabad', 'jaipur', 'surat',
                           'lucknow', 'kanpur', 'nagpur', 'indore', 'thane'];
      if (indianCities.any((city) => lowerAddress.contains(city))) {
        formattedAddress = '$cleanAddress, India';
      }
    }
    
    // Try multiple address formats
    final addressesToTry = [
      formattedAddress,
      if (formattedAddress != cleanAddress) cleanAddress,
      // Try without country if it was added
      if (formattedAddress.endsWith(', India')) cleanAddress,
    ];
    
    for (final addr in addressesToTry) {
      if (addr.isEmpty) continue;
      
      try {
        final locations = await locationFromAddress(addr);
        if (locations.isNotEmpty) {
          return locations.map((location) {
            return {
              'latitude': location.latitude,
              'longitude': location.longitude,
            };
          }).toList();
        }
      } catch (e) {
        // Continue to next address format
        print('Error geocoding address "$addr": $e');
        continue;
      }
    }
    
    return [];
  }
}

