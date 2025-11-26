import 'package:flutter/material.dart';

import '../../components/shadcn/shadcn.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/task_location.dart';
import '../../services/location_service.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    this.location,
    this.onLocationChanged,
    this.enabled = true,
  });

  final TaskLocation? location;
  final ValueChanged<TaskLocation?>? onLocationChanged;
  final bool enabled;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _locationService = LocationService();
  final _addressController = TextEditingController();
  final _placeNameController = TextEditingController();
  bool _isLoading = false;
  bool _isManualInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.location != null && !widget.location!.isEmpty) {
      _addressController.text = widget.location!.address;
      _placeNameController.text = widget.location!.placeName ?? '';
    }
  }

  @override
  void didUpdateWidget(LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      if (widget.location != null && !widget.location!.isEmpty) {
        _addressController.text = widget.location!.address;
        _placeNameController.text = widget.location!.placeName ?? '';
        _isManualInput = false;
      } else if (widget.location == null || widget.location!.isEmpty) {
        _addressController.clear();
        _placeNameController.clear();
        _isManualInput = false;
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _placeNameController.dispose();
    super.dispose();
  }

  Future<void> _pickCurrentLocation() async {
    if (!widget.enabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      final details = await _locationService.getLocationDetails(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final address = details['address'] as String;
      final placeName = details['placeName'] as String?;

      // Ensure we have a valid address, not "Unable to get address"
      String finalAddress = address;
      if (address == 'Unable to get address' || address == 'Unknown location' || address.isEmpty) {
        finalAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }

      final location = TaskLocation(
        address: finalAddress,
        latitude: position.latitude,
        longitude: position.longitude,
        placeName: placeName ?? finalAddress,
      );

      widget.onLocationChanged?.call(location);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Success',
              description: 'Location saved successfully',
              variant: ShadAlertVariant.success,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Error',
              description: e.toString().replaceFirst('Exception: ', ''),
              variant: ShadAlertVariant.destructive,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearLocation() {
    _addressController.clear();
    _placeNameController.clear();
    setState(() {
      _isManualInput = false;
    });
    widget.onLocationChanged?.call(null);
  }

  void _toggleManualInput() {
    setState(() {
      _isManualInput = !_isManualInput;
      if (!_isManualInput) {
        _addressController.clear();
        _placeNameController.clear();
      }
    });
  }

  Future<void> _geocodeAddress() async {
    if (_addressController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final addressText = _addressController.text.trim();
      final placeNameText = _placeNameController.text.trim();
      
      // Try to geocode the address
      final locations = await _locationService.geocodeAddress(addressText);
      
      if (locations.isNotEmpty) {
        // Geocoding successful - use coordinates
        final location = locations.first;
        final locationData = TaskLocation(
          address: addressText,
          latitude: location['latitude'] as double,
          longitude: location['longitude'] as double,
          placeName: placeNameText.isEmpty ? null : placeNameText,
        );
        widget.onLocationChanged?.call(locationData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ShadAlert(
                title: 'Success',
                description: 'Location saved successfully',
                variant: ShadAlertVariant.success,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Geocoding failed - save address without coordinates
        final locationData = TaskLocation(
          address: addressText,
          latitude: 0.0,
          longitude: 0.0,
          placeName: placeNameText.isEmpty ? null : placeNameText,
          notes: 'Manual address entry',
        );
        widget.onLocationChanged?.call(locationData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ShadAlert(
                title: 'Location Saved',
                description: 'Address saved (coordinates not available)',
                variant: ShadAlertVariant.success,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.all(16),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
      setState(() {
        _isManualInput = false;
      });
    } catch (e) {
      // If geocoding fails completely, still save the manual address
      final addressText = _addressController.text.trim();
      final placeNameText = _placeNameController.text.trim();
      
      final locationData = TaskLocation(
        address: addressText,
        latitude: 0.0,
        longitude: 0.0,
        placeName: placeNameText.isEmpty ? null : placeNameText,
        notes: 'Manual address entry',
      );
      widget.onLocationChanged?.call(locationData);
      setState(() {
        _isManualInput = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ShadAlert(
              title: 'Location Saved',
              description: 'Address saved successfully',
              variant: ShadAlertVariant.success,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getDisplayAddress() {
    if (widget.location == null) return '';
    
    final address = widget.location!.address;
    final placeName = widget.location!.placeName;
    
    // If address is an error message or empty, use placeName or coordinates
    if (address.isEmpty || 
        address == 'Unable to get address' || 
        address == 'Unknown location') {
      if (placeName != null && placeName.isNotEmpty) {
        return placeName;
      }
      if (widget.location!.latitude != 0.0 && widget.location!.longitude != 0.0) {
        return '${widget.location!.latitude.toStringAsFixed(6)}, ${widget.location!.longitude.toStringAsFixed(6)}';
      }
      return 'Location set';
    }
    
    // If placeName exists and is different from address, show placeName as title and address below
    // Otherwise, just show address
    return address;
  }

  void _saveManualLocation() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ShadAlert(
            title: 'Validation Error',
            description: 'Please enter an address',
            variant: ShadAlertVariant.destructive,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _geocodeAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add location for this task',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (widget.location != null && widget.enabled && !_isManualInput)
                  ShadButton(
                    onPressed: _clearLocation,
                    variant: ShadButtonVariant.outline,
                    size: ShadButtonSize.sm,
                    icon: const Icon(Icons.clear, size: 18),
                    child: const Text('Clear'),
                  ),
                if (widget.location != null && widget.enabled && !_isManualInput)
                  const SizedBox(width: AppSpacing.sm),
                ShadButton(
                  onPressed: widget.enabled && !_isLoading && !_isManualInput
                      ? _toggleManualInput
                      : null,
                  variant: ShadButtonVariant.outline,
                  size: ShadButtonSize.sm,
                  disabled: !widget.enabled || _isLoading || _isManualInput,
                  icon: const Icon(Icons.edit_location, size: 18),
                  child: const Text('Enter Address'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ShadButton(
                  onPressed: widget.enabled && !_isLoading && !_isManualInput
                      ? _pickCurrentLocation
                      : null,
                  variant: ShadButtonVariant.outline,
                  size: ShadButtonSize.sm,
                  disabled: !widget.enabled || _isLoading || _isManualInput,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.location_on, size: 18),
                  child: const Text('Use Current'),
                ),
              ],
            ),
          ],
        ),
        if (_isManualInput) ...[
          const SizedBox(height: AppSpacing.md),
          ShadInput(
            controller: _placeNameController,
            label: 'Place Name (Optional)',
            hintText: 'e.g., Office Building, Meeting Room',
            prefixIcon: const Icon(Icons.place, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          ShadInput(
            controller: _addressController,
            label: 'Address *',
            hintText: 'Enter full address',
            prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ShadButton(
                onPressed: widget.enabled && !_isLoading ? _saveManualLocation : null,
                variant: ShadButtonVariant.default_,
                size: ShadButtonSize.sm,
                disabled: !widget.enabled || _isLoading,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 18),
                child: const Text('Save Location'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShadButton(
                onPressed: widget.enabled ? _toggleManualInput : null,
                variant: ShadButtonVariant.outline,
                size: ShadButtonSize.sm,
                disabled: !widget.enabled,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
        if (widget.location != null && !widget.location!.isEmpty && !_isManualInput) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.location!.placeName != null && 
                          widget.location!.placeName!.isNotEmpty &&
                          widget.location!.placeName != widget.location!.address)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            widget.location!.placeName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      Text(
                        _getDisplayAddress(),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

