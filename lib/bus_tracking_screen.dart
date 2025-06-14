import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_database/firebase_database.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  // Destination
  final LatLng _sathyabama = const LatLng(12.873142366931416, 80.2260014936225);

  // Debounce/routing
  final Duration _debounceDuration = const Duration(milliseconds: 500);
  final double _updateThreshold = 25; // in meters

  // Home boarding point (loaded from prefs)
  late LatLng _homeLocation;

  // Bus location (from RTDB)
  LatLng? _busLocation;
  bool _busHasUpdated = false;

  // Person’s own location
  late LatLng _personLocation;

  // Map controller & polylines
  final MapController _mapController = MapController();
  List<LatLng> _homeToBusRoute = [];
  List<LatLng> _busToCollegeRoute = [];

  // Loading flag
  bool _isLoading = true;

  // Debounce timers + last routed point
  Timer? _locationDebounce;
  LatLng? _lastBusLocationUsedForRoute;

  // Firebase refs
  final DatabaseReference _busLocationRef = FirebaseDatabase.instance
      .ref('bus/location');
  final DatabaseReference _peopleCountRef =
  FirebaseDatabase.instance.ref('bus/people_count');

  // Holds the latest people count
  int _peopleCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAll();
    _listenToBusLocation();
  }

  Future<void> _initializeAll() async {
    await _loadHomeLocation();
    await _getPersonLocation();
    await _fetchAndDrawRoutes();
    setState(() => _isLoading = false);
    _startPersonLocationUpdates();
  }

  Future<void> _loadHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('boarding_lat') ?? 13.10865287838255;
    final lng = prefs.getDouble('boarding_lng') ?? 80.2413197801336;
    _homeLocation = LatLng(lat, lng);
  }

  Future<void> _getPersonLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _personLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      _personLocation = _homeLocation;
    }
  }

  void _listenToBusLocation() {
    _busLocationRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      final rawLat = data['latitude'], rawLng = data['longitude'];
      if (rawLat is num && rawLng is num) {
        final newLoc = LatLng(rawLat.toDouble(), rawLng.toDouble());
        _onBusLocationChanged(newLoc);
      }
    }, onError: (err) {
      debugPrint('RTDB listen error: $err');
    });
  }

  void _onBusLocationChanged(LatLng newLoc) {
    if (_busLocation != null &&
        _distanceBetween(_busLocation!, newLoc) < _updateThreshold) {
      return;
    }
    _busLocation = newLoc;
    _busHasUpdated = true;
    _debounceRouteUpdate(newLoc);
    setState(() {});
  }

  void _debounceRouteUpdate(LatLng newLoc) {
    _locationDebounce?.cancel();
    _locationDebounce = Timer(_debounceDuration, () {
      if (_lastBusLocationUsedForRoute == null ||
          _distanceBetween(_lastBusLocationUsedForRoute!, newLoc) >
              _updateThreshold) {
        _lastBusLocationUsedForRoute = newLoc;
        _fetchAndDrawRoutes();
      }
    });
  }

  void _startPersonLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings:
      const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 25),
    ).listen((pos) {
      _personLocation = LatLng(pos.latitude, pos.longitude);
      setState(() {});
    });
  }

  Future<void> _fetchAndDrawRoutes() async {
    final homeBus =
    await _getRoute(_homeLocation, _busLocation ?? _homeLocation);
    final busCollege =
    await _getRoute(_busLocation ?? _homeLocation, _sathyabama);
    setState(() {
      _homeToBusRoute = homeBus;
      _busToCollegeRoute = busCollege;
    });
  }

  Future<List<LatLng>> _getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?geometries=polyline&overview=full',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('OSRM error ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body);
    final poly = data['routes'][0]['geometry'] as String;
    return PolylinePoints()
        .decodePolyline(poly)
        .map((e) => LatLng(e.latitude, e.longitude))
        .toList();
  }

  double _distanceBetween(LatLng a, LatLng b) =>
      const Distance().as(LengthUnit.Meter, a, b);

  Future<void> _onRefreshPressed() async {
    setState(() => _isLoading = true);
    await _getPersonLocation();
    await _fetchAndDrawRoutes();
    setState(() => _isLoading = false);
  }

  /// Reads `/bus/people_count` once and shows it in a dialog.
  Future<void> _fetchPeopleCount() async {
    try {
      final snap = await _peopleCountRef.get();
      final val = snap.value;
      print('Fetched value: $val'); // <-- Add this
      if (val == null) {
        print('people_count not found!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('People count not found.')),
        );
        return;
      }
      setState(() {
        _peopleCountRef.onValue.listen((DatabaseEvent event) {
          final val = event.snapshot.value;
          setState(() {
            _peopleCount = (val is int) ? val : int.tryParse(val.toString()) ?? 0;
          });
        });

      });
      _showPeopleCountPopup();
    } catch (e) {
      print('Error fetching people count: $e');
    }
  }


  void _showPeopleCountPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('People Count'),
        content: Text('There are $_peopleCount people on the bus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SATHYABAMA BUS SYSTEM"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _homeLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _homeLocation,
                    child: const Icon(Icons.home_rounded,
                        color: Colors.purple, size: 40),
                  ),
                  Marker(
                    width: 40,
                    height: 40,
                    point: _sathyabama,
                    child: const Icon(Icons.school_rounded,
                        color: Colors.red, size: 40),
                  ),
                  if (_busHasUpdated && _busLocation != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: _busLocation!,
                      child: const Icon(Icons.directions_bus,
                          color: Colors.black, size: 40),
                    ),
                  Marker(
                    width: 40,
                    height: 40,
                    point: _personLocation,
                    child: const Icon(Icons.person,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _homeToBusRoute,
                    color: Colors.black.withOpacity(0.3),
                    strokeWidth: 10.0,
                  ),
                  Polyline(
                    points: _homeToBusRoute,
                    color: Colors.green,
                    strokeWidth: 6.0,
                  ),
                  Polyline(
                    points: _busToCollegeRoute,
                    color: Colors.black.withOpacity(0.3),
                    strokeWidth: 10.0,
                  ),
                  Polyline(
                    points: _busToCollegeRoute,
                    color: Colors.blue,
                    strokeWidth: 6.0,
                  ),
                ],
              ),
            ],
          ),

          // 🧍 People count widget
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '$_peopleCount onboard',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _onRefreshPressed,
            backgroundColor: Colors.green,
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/boarding'),
            child: const Icon(Icons.edit_location),
            backgroundColor: Colors.orange,
          ),
          FloatingActionButton(
            onPressed: () {
               {
                _mapController.move(_personLocation, 16.0);
              }
            },
            backgroundColor: Colors.white70,
            tooltip: 'Center on Bus',
            child: const Icon(Icons.navigation),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _fetchPeopleCount,
            backgroundColor: Colors.blue,
            tooltip: 'Show People Count',
            child: const Icon(Icons.people),
          ),
        ],
      ),

    );
  }
}
