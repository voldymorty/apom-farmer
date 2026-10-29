import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:client/global/colortheme.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  String _selectedAddress = "Fetching address...";

  String? _selectedPincode;

  bool _isLoading = true;
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  List<LocationSuggestion> _searchResults = [];
  Timer? _debounceTimer;

  final Set<Marker> _markers = {};

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(11.0168, 76.9558), // Coimbatore as default
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedForeverDialog();
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = currentLatLng;
        _selectedPosition = widget.initialPosition ?? currentLatLng;
        _isLoading = false;
      });

      // Move camera to current location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedPosition!, zoom: 15.0),
        ),
      );

      // Add marker and get address
      _addMarker(_selectedPosition!);
      _getAddressFromLatLng(_selectedPosition!);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Error getting location: ${e.toString()}");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<Location> locations = await locationFromAddress(query);

      List<LocationSuggestion> suggestions = [];
      // Limit to 5 results for better performance
      for (var loc in locations.take(5)) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String address = _formatAddress(place);
            suggestions.add(
              LocationSuggestion(location: loc, displayAddress: address),
            );
          }
        } catch (e) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = suggestions;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectSearchResult(LocationSuggestion suggestion) async {
    final position = LatLng(
      suggestion.location.latitude,
      suggestion.location.longitude,
    );

    setState(() {
      _selectedPosition = position;
      _selectedAddress = suggestion.displayAddress;
      _searchResults = [];
      _searchController.text = suggestion.displayAddress;
      _isSearching = false;
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 16.0),
      ),
    );

    _addMarker(position);
    _getAddressFromLatLng(position);

    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          onDragEnd: (newPosition) {
            setState(() {
              _selectedPosition = newPosition;
            });
            _getAddressFromLatLng(newPosition);
          },
        ),
      );
    });
  }

  // Future<void> _getAddressFromLatLng(LatLng position) async {
  //   setState(() => _isLoadingAddress = true);

  //   try {
  //     List<Placemark> placemarks = await placemarkFromCoordinates(
  //       position.latitude,
  //       position.longitude,
  //     );

  //     if (placemarks.isNotEmpty) {
  //       Placemark place = placemarks[0];
  //       setState(() {
  //         _selectedAddress = _formatAddress(place);
  //         _isLoadingAddress = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _selectedAddress = "Unable to fetch address";
  //       _isLoadingAddress = false;
  //     });
  //   }
  // }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        setState(() {
          _selectedAddress = _formatAddress(place);

          _selectedPincode = place.postalCode;

          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = "Unable to fetch address";
        _selectedPincode = null;
        _isLoadingAddress = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.name != null && place.name!.isNotEmpty) {
      addressParts.add(place.name!);
    }
    if (place.street != null &&
        place.street!.isNotEmpty &&
        place.street != place.name) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }

    return addressParts.join(', ');
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _addMarker(position);
    _getAddressFromLatLng(position);
  }

  void _onMyLocationPressed() async {
    if (_currentPosition != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 15.0),
        ),
      );

      setState(() {
        _selectedPosition = _currentPosition;
      });
      _addMarker(_currentPosition!);
      _getAddressFromLatLng(_currentPosition!);
    }
  }

  // void _confirmLocation() {
  //   if (_selectedPosition != null) {
  //     Navigator.pop(context, {
  //       'latitude': _selectedPosition!.latitude,
  //       'longitude': _selectedPosition!.longitude,
  //       'address': _selectedAddress,
  //     });
  //   }
  // }

  void _confirmLocation() {
    if (_selectedPosition != null) {
      Navigator.pop(context, {
        'latitude': _selectedPosition!.latitude,
        'longitude': _selectedPosition!.longitude,
        'address': _selectedAddress,

        // Reverse geocoded details
        'pincode': _selectedPincode,
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Please grant location permission to use this feature.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _getCurrentLocation();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Permission Denied'),
            content: const Text(
              'Location permission is permanently denied. Please enable it from app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryGreen),
                    const SizedBox(height: 16),
                    const Text('Getting your location...'),
                  ],
                ),
              )
              : Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _defaultPosition,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    markers: _markers,
                    onTap: _onMapTapped,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                  ),

                  // Search bar at top
                  Positioned(
                    top: 70,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search location...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.primaryGreen,
                              ),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchResults = [];
                                          });
                                        },
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                            onSubmitted: _searchPlaces,
                          ),
                        ),

                        // Search results dropdown
                        if (_isSearching)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Searching...'),
                              ],
                            ),
                          ),

                        if (_searchResults.isNotEmpty && !_isSearching)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final suggestion = _searchResults[index];
                                return ListTile(
                                  leading: Icon(
                                    Icons.place,
                                    color: AppColors.primaryGreen,
                                  ),
                                  title: Text(
                                    suggestion.displayAddress,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  onTap: () => _selectSearchResult(suggestion),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Address card
                  Positioned(
                    bottom: 90,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppColors.primaryGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Selected Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _isLoadingAddress
                                ? Row(
                                  children: [
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Fetching address...'),
                                  ],
                                )
                                : Text(
                                  _selectedAddress,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            if (_selectedPosition != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}, '
                                'Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // My Location button
                  Positioned(
                    bottom: 240,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'myLocation',
                      backgroundColor: Colors.white,
                      onPressed: _onMyLocationPressed,
                      child: Icon(
                        Icons.my_location,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),

                  // Confirm button at bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed:
                            _selectedPosition != null ? _confirmLocation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class LocationSuggestion {
  final Location location;
  final String displayAddress;

  LocationSuggestion({required this.location, required this.displayAddress});
}
