import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  // Cache lokasi terakhir yang berhasil didapatkan
  LatLng? _cachedLocation;
  String _currentAddress = "Mencari alamat...";
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _handleLocationFailure("Layanan lokasi/GPS perangkat dinonaktifkan.");
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _handleLocationFailure("Izin akses lokasi ditolak oleh pengguna.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _handleLocationFailure("Izin lokasi ditolak secara permanen.");
        return;
      }

      // 1. Dapatkan posisi saat ini dengan desiredAccuracy: LocationAccuracy.high
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _updateLocation(position);

      // 2. Mulai GPS Stream dengan LocationSettings (accuracy: high, distanceFilter: 10 meter)
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position newPosition) {
          _updateLocation(newPosition);
        },
        onError: (error) {
          _handleLocationFailure("Error streaming GPS: $error");
        },
      );

    } catch (e) {
      _handleLocationFailure("GPS/Lokasi tidak didukung pada platform saat ini: $e");
    }
  }

  void _updateLocation(Position position) {
    final newLatLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocation = newLatLng;
      _cachedLocation = newLatLng; // Simpan di cache in-memory
      _isError = false;
      _errorMessage = "";
    });
    _reverseGeocode(newLatLng);
  }

  void _handleLocationFailure(String message) {
    if (_cachedLocation != null) {
      setState(() {
        _currentLocation = _cachedLocation;
        _isError = true;
        _errorMessage = "$message Menggunakan lokasi cache terakhir.";
      });
      _reverseGeocode(_cachedLocation!);
    } else {
      _setMockLocation(message);
    }
  }

  void _setMockLocation(String message) {
    // Koordinat Universitas Jember sebagai mock lokasi default
    setState(() {
      _currentLocation = const LatLng(-8.184486, 113.668076);
      _isError = true;
      _errorMessage = "$message Menggunakan lokasi default (Universitas Jember).";
    });
    _reverseGeocode(const LatLng(-8.184486, 113.668076));
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}";
          // Membersihkan koma-koma ganda jika ada nilai null/kosong
          _currentAddress = _currentAddress
              .replaceAll(RegExp(r',\s*,'), ',')
              .trim()
              .replaceAll(RegExp(r'^,\s*'), '')
              .replaceAll(RegExp(r',\s*$'), '');
          
          if (_currentAddress.isEmpty) {
            _currentAddress = "Alamat tidak spesifik (${location.latitude}, ${location.longitude})";
          }
        });
      } else {
        setState(() {
          _currentAddress = "Alamat tidak ditemukan untuk koordinat ini.";
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal memuat alamat: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map & GPS'),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
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
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_city, color: Colors.blue, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Alamat Terdeteksi:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
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
