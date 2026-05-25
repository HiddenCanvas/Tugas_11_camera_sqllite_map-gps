import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapGpsPage extends StatefulWidget {
  const MapGpsPage({super.key});

  @override
  State<MapGpsPage> createState() => _MapGpsPageState();
}

class _MapGpsPageState extends State<MapGpsPage> {
  LatLng? _currentLocation;
  bool _isError = false;
  String _errorMessage = "";
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setMockLocation("Layanan lokasi/GPS perangkat dinonaktifkan.");
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setMockLocation("Izin akses lokasi ditolak oleh pengguna.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setMockLocation("Izin lokasi ditolak secara permanen.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      _setMockLocation("GPS/Lokasi tidak didukung pada platform saat ini: $e");
    }
  }

  void _setMockLocation(String message) {
    // Koordinat Universitas Jember sebagai mock lokasi default
    setState(() {
      _currentLocation = const LatLng(-8.184486, 113.668076);
      _isError = true;
      _errorMessage = "$message Menggunakan lokasi default (Universitas Jember).";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map & GPS'),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation!,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.unej.pbm.camerasqllitemapgps',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isError)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      color: Colors.orange.shade100,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _currentLocation == null
          ? null
          : FloatingActionButton(
              onPressed: () {
                _mapController.move(_currentLocation!, 16.0);
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
    );
  }
}
