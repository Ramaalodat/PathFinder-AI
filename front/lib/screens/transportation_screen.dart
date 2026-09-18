import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/transportation_service.dart';
import '../config/api_config.dart';

class TransportationScreen extends StatefulWidget {
  const TransportationScreen({super.key});

  @override
  State<TransportationScreen> createState() => _TransportationScreenState();
}

class _TransportationScreenState extends State<TransportationScreen> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  
  // UI State
  bool _showSearchResults = false;
  bool _showDirections = false;
  bool _isLoadingLocation = false;
  MapType _currentMapType = MapType.normal;
  bool _isSelectingStart = false;
  bool _isSelectingEnd = false;
  
  // Data
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedRoute;
  List<Map<String, dynamic>> _nearbyStations = [];
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _isLoadingSuggestions = false;
  
  // Google Maps API Key
  static const String _googleMapsApiKey = 'AIzaSyBAuBd-eTLmk6a_e6q-QhWIP4pp85tNCvw';

  @override
  void initState() {
    super.initState();
    // Delay location request slightly to ensure map is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      print('Starting location request...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showLocationServiceDialog();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showLocationPermissionDialog();
        return;
      }

      print('Getting current position...');
      
      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print('Position received: ${position.latitude}, ${position.longitude}');
      
      // Check if we got a valid position (not 0,0 which is default for emulator)
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        print('Invalid position received (0,0), using fallback location for emulator');
        // Use a fallback location for emulator testing
        final fallbackPosition = Position(
          latitude: 40.7128, // New York City
          longitude: -74.0060,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        _handleLocationReceived(fallbackPosition);
        return;
      }

      _handleLocationReceived(position);
      
      print('Location setup completed successfully');
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      print('Location error: $e');
      
      // For emulator testing, use a fallback location
      print('Using fallback location for emulator testing');
      final fallbackPosition = Position(
        latitude: 40.7128, // New York City
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      _handleLocationReceived(fallbackPosition);
    }
  }

  void _handleLocationReceived(Position position) {
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });

    print('Current location set: $_currentLocation');

    // Add current location marker
    _addMarker(
      _currentLocation!,
      'Current Location',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    print('Marker added for current location');

    // Move camera to current location
    if (_mapController != null) {
      print('Moving camera to current location');
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    } else {
      print('Map controller is null, will move camera when map is created');
    }

    // Get nearby transportation data
    _getNearbyTransportation();
  }

  void _setTestLocation() {
    print('Setting test location for emulator');
    final testPosition = Position(
      latitude: 40.7128, // New York City
      longitude: -74.0060,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    _handleLocationReceived(testPosition);
  }

  void _handleMapTap(LatLng position) async {
    if (_isSelectingStart) {
      // Get address for the tapped location
      final address = await _getAddressFromCoordinates(position);
      _fromController.text = address;
      _addMarker(position, 'Starting Point', BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
      setState(() {
        _isSelectingStart = false;
      });
    } else if (_isSelectingEnd) {
      // Get address for the tapped location
      final address = await _getAddressFromCoordinates(position);
      _toController.text = address;
      _addMarker(position, 'Destination', BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));
      setState(() {
        _isSelectingEnd = false;
      });
    }
  }

  Future<String> _getAddressFromCoordinates(LatLng position) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$_googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] ?? 'Unknown location';
        }
      }
      return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    }
  }

  Future<void> _getLocationSuggestions(String query) async {
    if (query.length < 3) {
      setState(() {
        _locationSuggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // Try Places API first
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleMapsApiKey&types=geocode';
      print('🔍 Fetching suggestions for: $query');
      print('🌐 URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Parsed data: $data');
        
        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = List<Map<String, dynamic>>.from(data['predictions']);
          print('🎯 Found ${predictions.length} suggestions');
          setState(() {
            _locationSuggestions = predictions;
            _isLoadingSuggestions = false;
          });
        } else {
          print('❌ API error: ${data['status']} - ${data['error_message']}');
          // Try fallback with Geocoding API
          _getFallbackSuggestions(query);
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        // Try fallback with Geocoding API
        _getFallbackSuggestions(query);
      }
    } catch (e) {
      print('❌ Exception: $e');
      // Try fallback with Geocoding API
      _getFallbackSuggestions(query);
    }
  }

  Future<void> _getFallbackSuggestions(String query) async {
    try {
      // Fallback: Use Geocoding API to search for places
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$_googleMapsApiKey';
      print('🔄 Trying fallback geocoding for: $query');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          final results = List<Map<String, dynamic>>.from(data['results']);
          print('🎯 Fallback found ${results.length} suggestions');
          
          // Convert geocoding results to suggestion format
          final suggestions = results.map((result) => {
            'description': result['formatted_address'],
            'place_id': result['place_id'],
          }).toList();
          
          setState(() {
            _locationSuggestions = suggestions;
            _isLoadingSuggestions = false;
          });
        } else {
          setState(() {
            _locationSuggestions = [];
            _isLoadingSuggestions = false;
          });
        }
      } else {
        setState(() {
          _locationSuggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      print('❌ Fallback exception: $e');
      setState(() {
        _locationSuggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }



  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('This app needs location permission to show your position on the map.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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

  Future<void> _getNearbyTransportation() async {
    if (_currentLocation == null) return;

    try {
      final result = await TransportationService.getNearbyTransportation(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radius: 1000,
        transportType: 'all',
      );

      if (result['success'] == true) {
        setState(() {
          _nearbyStations = List<Map<String, dynamic>>.from(
            result['data']['nearbyOptions'] ?? [],
          );
        });
        _addTransportationMarkers();
      }
    } catch (e) {
      print('Error getting nearby transportation: $e');
    }
  }

  void _addTransportationMarkers() {
    for (int i = 0; i < _nearbyStations.length; i++) {
      final station = _nearbyStations[i];
      if (station['coordinates'] != null) {
        final coords = station['coordinates'];
        final position = LatLng(coords['lat'], coords['lng']);
        
        _addMarker(
          position,
          station['name'] ?? 'Transportation Station',
          station['type'] == 'bus' 
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      }
    }
  }

  void _addMarker(LatLng position, String title, BitmapDescriptor icon) {
    print('Adding marker: $title at $position');
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(title),
          position: position,
          icon: icon,
          infoWindow: InfoWindow(title: title),
        ),
      );
    });
    print('Total markers: ${_markers.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Google Maps
          _buildGoogleMap(),
          
          // Top App Bar
          _buildTopAppBar(),
          
          // Search Bar
          _buildSearchBar(),
          
          // Search Results
          if (_showSearchResults) _buildSearchResults(),
          
          // Directions Panel
          if (_showDirections) _buildDirectionsPanel(),
          
          
          // Map Controls
          _buildMapControls(),
          
          // Location Status
          if (_currentLocation == null && !_isLoadingLocation)
            _buildLocationPrompt(),
          
          // Map Selection Indicator
          if (_isSelectingStart || _isSelectingEnd)
            _buildMapSelectionIndicator(),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    if (_isLoadingLocation) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                'Getting your location...',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        print('Map created, current location: $_currentLocation');
        
        // If we already have a current location, move camera to it
        if (_currentLocation != null) {
          print('Moving camera to existing current location');
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
          );
        } else {
          print('No current location yet, will move camera when location is obtained');
        }
      },
      initialCameraPosition: CameraPosition(
        target: _currentLocation ?? const LatLng(31.9539, 35.9106), // Amman, Jordan
        zoom: 15.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: _currentMapType,
      zoomControlsEnabled: false,
      compassEnabled: true,
      onTap: (LatLng position) {
        setState(() {
          _showSearchResults = false;
          _locationSuggestions = []; // Clear suggestions when map is tapped
        });
        
        // Handle point selection
        if (_isSelectingStart || _isSelectingEnd) {
          _handleMapTap(position);
        }
      },
    );
  }

  Widget _buildTopAppBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back button only
            _buildFloatingButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.black87,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildLocationField(
              controller: _fromController,
              icon: Icons.circle,
              iconColor: Colors.blue,
              hintText: 'Choose starting point',
              isStartField: true,
            ),
            Container(
              height: 1,
              color: Colors.grey[200],
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            _buildLocationField(
              controller: _toController,
              icon: Icons.location_on,
              iconColor: Colors.red,
              hintText: 'Choose destination',
              isStartField: false,
            ),
            // Get Directions Button
            if (_fromController.text.isNotEmpty && _toController.text.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _getDirections,
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text('Find Closest Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            
            // Test API Button (for debugging) - HIDDEN
            // Container(
            //   width: double.infinity,
            //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   child: ElevatedButton.icon(
            //     onPressed: _testApiConnection,
            //     icon: const Icon(Icons.bug_report, size: 18),
            //     label: const Text('Test API Connection'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.orange[600],
            //       foregroundColor: Colors.white,
            //       padding: const EdgeInsets.symmetric(vertical: 8),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hintText,
    required bool isStartField,
  }) {
    final isSelecting = isStartField ? _isSelectingStart : _isSelectingEnd;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelecting ? Colors.orange : iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelecting ? Icons.my_location : icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: isSelecting ? 'Tap on map to select location' : hintText,
                    hintStyle: GoogleFonts.roboto(
                      color: isSelecting ? Colors.orange[600] : Colors.grey[600],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: _isLoadingSuggestions 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onTap: () {
                    if (!isSelecting) {
                      setState(() {
                        _showSearchResults = false; // Hide search results when typing
                      });
                    }
                  },
                  onChanged: (value) {
                    if (!isSelecting) {
                      _getLocationSuggestions(value);
                    }
                  },
                  onTapOutside: (event) {
                    setState(() {
                      _locationSuggestions = [];
                    });
                  },
                ),
                // Show suggestions dropdown
                if (_locationSuggestions.isNotEmpty && !isSelecting)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
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
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _locationSuggestions.length > 3 ? 3 : _locationSuggestions.length, // Limit to 3 to avoid covering destination
                      itemBuilder: (context, index) {
                        final suggestion = _locationSuggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, size: 20, color: Colors.grey),
                          title: Text(
                            suggestion['description'] ?? '',
                            style: GoogleFonts.roboto(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            controller.text = suggestion['description'] ?? '';
                            setState(() {
                              _locationSuggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Map selection button
          GestureDetector(
            onTap: () {
              setState(() {
                if (isStartField) {
                  _isSelectingStart = !_isSelectingStart;
                  _isSelectingEnd = false;
                } else {
                  _isSelectingEnd = !_isSelectingEnd;
                  _isSelectingStart = false;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelecting ? Colors.orange[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.map,
                color: isSelecting ? Colors.orange[600] : Colors.grey[600],
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                setState(() {});
              },
              child: Icon(
                Icons.clear,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Positioned(
      top: 220,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _searchResults.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No results found',
                    style: GoogleFonts.roboto(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return _buildSearchResultItem(result);
                },
              ),
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.location_on,
          color: Colors.blue[600],
          size: 20,
        ),
      ),
      title: Text(
        result['name'] ?? 'Unknown place',
        style: GoogleFonts.roboto(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        result['formatted_address'] ?? '',
        style: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _selectSearchResult(result),
    );
  }

  Widget _buildDirectionsPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Directions content
              Expanded(
                child: _selectedRoute != null
                    ? _buildRouteDetails(scrollController)
                    : const Center(
                        child: Text('No route selected'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildMapControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        children: [
          // My location button
          _buildMapControlButton(
            icon: Icons.my_location,
            onTap: _goToMyLocation,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          // Layers button
          _buildMapControlButton(
            icon: Icons.layers,
            onTap: _toggleLayers,
            color: Colors.grey[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  // Functionality methods
  void _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults.clear();
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      // Searching...
    });

    try {
      final results = await _searchPlaces(query);
      setState(() {
        _searchResults = results;
        _showSearchResults = true;
      });
    } catch (e) {
      setState(() {
        // Search failed
      });
      _showErrorDialog('Search Error', 'Failed to search places: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$_googleMapsApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['results'] ?? []);
        } else {
          print('Places API error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Places API error: $e');
      return [];
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['geometry']['location']['lat'];
    final lng = result['geometry']['location']['lng'];
    final location = LatLng(lat, lng);

    setState(() {
      _showSearchResults = false;
      _searchController.text = result['name'] ?? '';
    });

    // Add marker
    _addMarker(
      location,
      result['name'] ?? 'Selected Location',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    // Move camera to location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 15.0),
    );
  }

  Future<void> _getDirections() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      _showErrorDialog('Missing Information', 'Please enter both origin and destination');
      return;
    }

    setState(() {
      // Getting directions...
    });

    try {
      // Prepare request data
      final requestData = {
        'from': _fromController.text,
        'to': _toController.text,
        'mode': 'transit', // Always request transit mode for multiple options
        'preferences': {
          'maxTime': 60, // 60 minutes max
          'ecoFriendly': true, // Always prefer eco-friendly transit options
        }
      };

      print('🚀 Calling transportation API with data: $requestData');
      print('🌐 API URL: ${ApiConfig.transportationUrl}/options');

      // Call your backend transportation API
      final response = await http.post(
        Uri.parse('${ApiConfig.transportationUrl}/options'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Parsed response: $data');
        
        if (data['success'] == true) {
          // Handle different response structures
          List<Map<String, dynamic>> allRoutes = [];
          
          if (data['data'] != null) {
            // Check if it's Google Directions format (has routes array)
            if (data['data']['routes'] != null && (data['data']['routes'] as List).isNotEmpty) {
              final routes = data['data']['routes'] as List;
              allRoutes = routes.cast<Map<String, dynamic>>();
              print('🎯 Found ${allRoutes.length} Google Directions routes');
              
              // Log each route's summary
              for (int i = 0; i < allRoutes.length; i++) {
                final route = allRoutes[i];
                final summary = route['summary'] ?? 'Unknown route';
                final legs = route['legs'] as List? ?? [];
                if (legs.isNotEmpty) {
                  final duration = legs.first['duration']?['text'] ?? 'Unknown time';
                  final distance = legs.first['distance']?['text'] ?? 'Unknown distance';
                  print('   Route $i: $summary - $duration, $distance');
                }
              }
            }
            // Check if it's our custom format (has options array)
            else if (data['data']['options'] != null && (data['data']['options'] as List).isNotEmpty) {
              final options = data['data']['options'] as List;
              allRoutes = options.cast<Map<String, dynamic>>();
              print('🎯 Found ${allRoutes.length} custom route options');
            }
            // Check if data is directly a route object
            else if (data['data'] is Map) {
              allRoutes = [data['data'] as Map<String, dynamic>];
              print('🎯 Using direct data format');
            }
          }
          
          if (allRoutes.isNotEmpty) {
            print('✅ Successfully parsed ${allRoutes.length} routes');
            
            // Always use the first route (closest/fastest)
            final selectedRoute = allRoutes.first;
            _displayBackendRoute(selectedRoute);
            setState(() {
              _showDirections = true;
              _selectedRoute = selectedRoute;
            });
            
            print('🎯 Showing closest route: ${selectedRoute['summary'] ?? 'Unknown route'}');
          } else {
            print('❌ No route data found in response');
            _showErrorDialog('No Route Found', 'No transportation options found between the selected locations. Please try different locations.');
          }
        } else {
          print('❌ API returned success: false');
          final errorMsg = data['message'] ?? data['error'] ?? 'Unknown error';
          _showErrorDialog('API Error', 'Backend error: $errorMsg');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        _showErrorDialog('API Error', 'Server returned status ${response.statusCode}. Please check if your backend is running.');
      }
    } catch (e) {
      setState(() {
        // Directions failed
      });
      print('💥 Directions error: $e');
      _showErrorDialog('Directions Error', 'Failed to get directions: $e');
    }
  }

  void _displayBackendRoute(Map<String, dynamic> route) {
    print('🗺️ Displaying route: $route');
    
    final points = <LatLng>[];
    
    // Check if it's Google Directions format
    if (route['legs'] != null) {
      print('📍 Using Google Directions format');
      _displayGoogleDirectionsRoute(route);
      return;
    }
    
    // Check if it's our custom format with coordinates
    if (route['coordinates'] != null) {
      print('📍 Using custom coordinates format');
      final coords = route['coordinates'] as List;
      for (final coord in coords) {
        if (coord['lat'] != null && coord['lng'] != null) {
          points.add(LatLng(coord['lat'], coord['lng']));
        }
      }
    } else {
      // Fallback: create a simple line between origin and destination
      print('📍 Using fallback coordinates');
      final startLatLng = _currentLocation ?? const LatLng(40.7128, -74.0060);
      final endLatLng = LatLng(
        startLatLng.latitude + 0.01,
        startLatLng.longitude + 0.01,
      );
      points.addAll([startLatLng, endLatLng]);
    }

    if (points.isNotEmpty) {
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: _getRouteColor(route['type']),
            width: 5,
          ),
        );
      });
    }
  }

  void _displayGoogleDirectionsRoute(Map<String, dynamic> route) {
    final points = <LatLng>[];
    final legs = route['legs'] as List;
    
    for (final leg in legs) {
      final steps = leg['steps'] as List;
      for (final step in steps) {
        // Decode polyline if available
        if (step['polyline'] != null && step['polyline']['points'] != null) {
          final polylinePoints = _decodePolyline(step['polyline']['points']);
          points.addAll(polylinePoints);
        } else {
          // Fallback to start/end locations
          if (step['start_location'] != null) {
            final start = step['start_location'];
            points.add(LatLng(start['lat'], start['lng']));
          }
          if (step['end_location'] != null) {
            final end = step['end_location'];
            points.add(LatLng(end['lat'], end['lng']));
          }
        }
      }
    }

    if (points.isNotEmpty) {
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: _getRouteColor('transit'),
            width: 5,
          ),
        );
      });
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    // Simple polyline decoder (you might want to use a proper library)
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  Color _getRouteColor(String? type) {
    switch (type) {
      case 'bus':
        return Colors.green;
      case 'metro':
        return Colors.red;
      case 'walking':
        return Colors.blue;
      case 'cycling':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }


  void _goToMyLocation() {
    if (_currentLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    } else {
      // Try to get location again
      _getCurrentLocation();
    }
  }

  void _toggleLayers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Map Type',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMapTypeOption('Normal', Icons.map, MapType.normal),
                  _buildMapTypeOption('Satellite', Icons.satellite, MapType.satellite),
                  _buildMapTypeOption('Terrain', Icons.terrain, MapType.terrain),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(String title, IconData icon, MapType mapType) {
    final isSelected = _currentMapType == mapType;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: isSelected ? Colors.blue : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() {
          _currentMapType = mapType;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMenuOption('Settings', Icons.settings),
                  _buildMenuOption('Help', Icons.help),
                  _buildMenuOption('About', Icons.info),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          color: Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        // Handle menu option
      },
    );
  }

  Widget _buildRouteDetails(ScrollController? scrollController) {
    if (_selectedRoute == null) return const SizedBox.shrink();

    // Check if it's a backend route or Google route
    final isBackendRoute = _selectedRoute!.containsKey('type');
    
    if (isBackendRoute) {
      return _buildBackendRouteDetails(scrollController);
    } else {
      return _buildGoogleRouteDetails(scrollController);
    }
  }

  Widget _buildBackendRouteDetails(ScrollController? scrollController) {
    final route = _selectedRoute!;
    
    // Check if it's Google Directions format
    final isGoogleDirections = route['legs'] != null;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getRouteColor(route['type']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getRouteColor(route['type']).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getRouteColor(route['type']),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    _getTransportIcon(route['type'] ?? 'transit'),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGoogleDirections ? 'TRANSIT ROUTE' : '${route['type']?.toUpperCase() ?? 'TRANSPORT'} Route',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: _getRouteColor(route['type']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRouteTime(route),
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _getRouteDistance(route),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Start navigation
                  },
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRouteColor(route['type']),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Route summary
          _buildRouteSummary(route),
          const SizedBox(height: 20),
          
          // Route steps
          Expanded(
            child: isGoogleDirections 
                ? _buildGoogleDirectionsSteps(route)
                : _buildBackendRouteSteps(route),
          ),
        ],
      ),
    );
  }

  String _getRouteTime(Map<String, dynamic> route) {
    // Check for Google Directions format
    if (route['legs'] != null) {
      final legs = route['legs'] as List;
      if (legs.isNotEmpty) {
        final duration = legs.first['duration'];
        return duration?['text'] ?? 'Unknown time';
      }
    }
    
    // Check for custom format
    return route['estimatedTime'] ?? route['duration'] ?? 'Unknown time';
  }

  String _getRouteDistance(Map<String, dynamic> route) {
    // Check for Google Directions format
    if (route['legs'] != null) {
      final legs = route['legs'] as List;
      if (legs.isNotEmpty) {
        final distance = legs.first['distance'];
        return distance?['text'] ?? 'Unknown distance';
      }
    }
    
    // Check for custom format
    return route['cost'] ?? route['distance'] ?? 'Unknown cost';
  }

  Widget _buildRouteSummary(Map<String, dynamic> route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Summary',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'From',
                  _fromController.text,
                  Icons.location_on,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'To',
                  _toController.text,
                  Icons.flag,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleRouteDetails(ScrollController? scrollController) {
    final legs = _selectedRoute!['legs'] as List;
    final firstLeg = legs.isNotEmpty ? legs[0] : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route summary
          if (firstLeg != null) ...[
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.directions_transit,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstLeg['duration']['text'],
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        firstLeg['distance']['text'],
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Start navigation
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Start',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          // Route steps
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: legs.length,
              itemBuilder: (context, index) {
                final leg = legs[index];
                return _buildRouteStep(leg, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleDirectionsSteps(Map<String, dynamic> route) {
    final legs = route['legs'] as List;
    final allSteps = <Map<String, dynamic>>[];
    
    // Collect all steps from all legs
    for (final leg in legs) {
      final steps = leg['steps'] as List;
      for (final step in steps) {
        allSteps.add(step);
      }
    }
    
    print('🔍 Processing ${allSteps.length} steps for display');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step-by-Step Directions',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: allSteps.length,
            itemBuilder: (context, index) {
              final step = allSteps[index];
              final isLast = index == allSteps.length - 1;
              final instruction = _stripHtml(step['html_instructions'] ?? '');
              final duration = step['duration']?['text'] ?? '';
              final distance = step['distance']?['text'] ?? '';
              
              // Detect transport type from instruction
              final transportType = _detectTransportType(instruction);
              final stepIcon = _getStepIcon(instruction);
              final stepColor = _getTransportColor(transportType);
              
              print('Step $index: $instruction (Type: $transportType)');
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number and icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: stepColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          stepIcon,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Step content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: stepColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: stepColor.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instruction,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (transportType != 'walking') ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stepColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  transportType.toUpperCase(),
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: stepColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (duration.isNotEmpty || distance.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (duration.isNotEmpty) ...[
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      duration,
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  if (duration.isNotEmpty && distance.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                  ],
                                  if (distance.isNotEmpty) ...[
                                    Icon(
                                      Icons.straighten,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      distance,
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            if (!isLast) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: stepColor.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Next step',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: stepColor.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _detectTransportType(String instruction) {
    final lowerInstruction = instruction.toLowerCase();
    
    if (lowerInstruction.contains('bus') || lowerInstruction.contains('take the bus')) {
      return 'bus';
    } else if (lowerInstruction.contains('metro') || lowerInstruction.contains('subway') || 
               lowerInstruction.contains('train') || lowerInstruction.contains('rail')) {
      return 'metro';
    } else if (lowerInstruction.contains('walk') || lowerInstruction.contains('head')) {
      return 'walking';
    } else if (lowerInstruction.contains('bike') || lowerInstruction.contains('cycle')) {
      return 'cycling';
    } else if (lowerInstruction.contains('drive') || lowerInstruction.contains('car')) {
      return 'driving';
    } else if (lowerInstruction.contains('transit') || lowerInstruction.contains('public transport')) {
      return 'transit';
    }
    
    return 'transit'; // Default
  }

  Color _getTransportColor(String transportType) {
    switch (transportType) {
      case 'bus':
        return Colors.green;
      case 'metro':
        return Colors.red;
      case 'walking':
        return Colors.blue;
      case 'cycling':
        return Colors.orange;
      case 'driving':
        return Colors.purple;
      case 'transit':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getStepIcon(String instruction) {
    final lowerInstruction = instruction.toLowerCase();
    
    if (lowerInstruction.contains('bus')) {
      return Icons.directions_bus;
    } else if (lowerInstruction.contains('metro') || lowerInstruction.contains('subway') || 
               lowerInstruction.contains('train')) {
      return Icons.train;
    } else if (lowerInstruction.contains('walk') || lowerInstruction.contains('head')) {
      return Icons.directions_walk;
    } else if (lowerInstruction.contains('bike') || lowerInstruction.contains('cycle')) {
      return Icons.directions_bike;
    } else if (lowerInstruction.contains('drive') || lowerInstruction.contains('car')) {
      return Icons.directions_car;
    } else if (lowerInstruction.contains('transit') || lowerInstruction.contains('public transport')) {
      return Icons.directions_transit;
    }
    
    return Icons.directions; // Default
  }

  Widget _buildBackendRouteSteps(Map<String, dynamic> route) {
    final steps = route['route'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step-by-Step Directions',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number and icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getRouteColor(route['type']),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Step content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!isLast) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: _getRouteColor(route['type']).withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Next step',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: _getRouteColor(route['type']).withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteStep(Map<String, dynamic> leg, int index) {
    final steps = leg['steps'] as List;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) const Divider(),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getStepIcon(step['html_instructions']),
                  size: 16,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _stripHtml(step['html_instructions']),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                step['duration']['text'],
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  IconData _getTransportIcon(String mode) {
    switch (mode) {
      case 'driving':
        return Icons.directions_car;
      case 'transit':
        return Icons.directions_transit;
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
        return Icons.directions_bike;
      default:
        return Icons.directions;
    }
  }


  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Widget _buildLocationPrompt() {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              color: Colors.orange[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Location Not Available',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the button below to get your current location',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Get Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _setTestLocation,
                  icon: const Icon(Icons.location_city, size: 18),
                  label: const Text('Test Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSelectionIndicator() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[600],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isSelectingStart 
                    ? 'Tap on the map to select your starting point'
                    : 'Tap on the map to select your destination',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSelectingStart = false;
                  _isSelectingEnd = false;
                });
              },
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}