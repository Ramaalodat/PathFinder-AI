import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class MapTestScreen extends StatefulWidget {
  const MapTestScreen({super.key});

  @override
  State<MapTestScreen> createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  Set<Marker> _markers = {};
  
  // Test coordinates for Amman, Jordan
  static const LatLng _testLocation = LatLng(31.9539, 35.9106);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Map Test',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              print('Map created successfully!');
            },
            initialCameraPosition: const CameraPosition(
              target: _testLocation,
              zoom: 15.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            compassEnabled: true,
            onTap: (LatLng position) {
              setState(() {
                _markers.clear();
                _markers.add(
                  Marker(
                    markerId: MarkerId('test_marker'),
                    position: position,
                    infoWindow: InfoWindow(
                      title: 'Test Marker',
                      snippet: 'Lat: ${position.latitude}, Lng: ${position.longitude}',
                    ),
                  ),
                );
              });
            },
          ),
          // Test button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _addTestMarker,
              backgroundColor: Colors.blue[600],
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _addTestMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('test_marker'),
          position: _testLocation,
          infoWindow: const InfoWindow(
            title: 'Test Location',
            snippet: 'Amman, Jordan',
          ),
        ),
      );
    });
  }
}
