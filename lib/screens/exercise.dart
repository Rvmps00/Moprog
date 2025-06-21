import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcourse/models/exercise_models.dart';
import 'dart:math'; 
import 'package:uuid/uuid.dart'; 
import 'package:fitcourse/utils/my_colors.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

class ExerciseScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  
  const ExerciseScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with WidgetsBindingObserver {
  List<Status> _currentExerciseStatuses = [];
  bool _isExercising = false;
  StreamSubscription<Position>? _positionSubscription; 
  Timer? _stopwatchTimer; 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  final MapController _mapController = MapController();

  LatLng? _lastKnownLocation;
  bool _isMapInteracted = false; 

  // Local theme state for exercise screen only
  bool _isLightMode = false;
  
  int _currentDuration = 0; 
  double _currentDistance = 0.0; 
  double _currentSpeed = 0.0; 
  DateTime? _currentExerciseStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _loadLastKnownLocation();
    _loadExerciseState();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel(); 
    _stopwatchTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _saveExerciseState(); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveExerciseState();
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }
  }

  void _startExercise() {
    setState(() {
      _isExercising = true;
      _currentExerciseStatuses.clear();
      _currentDuration = 0; 
      _currentDistance = 0.0;
      _currentSpeed = 0.0;
      _currentExerciseStartTime = DateTime.now(); 
    });
    _startLocationTracking();
    _startStopwatch(); 
  }

  void _stopExercise() {
    setState(() {
      _isExercising = false;
    });
    _stopLocationTracking();
    _stopStopwatch(); 
    _calculateAndSaveExercise();
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentExerciseStartTime != null) {
        setState(() {
          _currentDuration = DateTime.now().difference(_currentExerciseStartTime!).inSeconds;
        });
      }
    });
  }

  void _stopStopwatch() {
    _stopwatchTimer?.cancel();
  }

  void _startLocationTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, 
      ),
    ).listen((Position position) {
      setState(() {
        _lastKnownLocation = LatLng(position.latitude, position.longitude);
      });
      _saveLastKnownLocation(position.latitude, position.longitude);

      if (!_isMapInteracted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );
      }

      if (_isExercising) {
        final newStatus = Status(
          id: _uuid.v4(),
          lat: position.latitude,
          lon: position.longitude,
          time: position.timestamp ?? DateTime.now(),
        );
        setState(() {
          _currentExerciseStatuses.add(newStatus);

          if (_currentExerciseStatuses.length >= 2) {
            final lastStatus = _currentExerciseStatuses[_currentExerciseStatuses.length - 2];
            final currentStatus = _currentExerciseStatuses.last;

            final segmentDistance = Geolocator.distanceBetween(
              lastStatus.lat,
              lastStatus.lon,
              currentStatus.lat,
              currentStatus.lon,
            );
            _currentDistance += segmentDistance;

            final timeDifference = currentStatus.time.difference(lastStatus.time).inSeconds;
            if (timeDifference > 0) {
              _currentSpeed = segmentDistance / timeDifference;
            } else {
              _currentSpeed = 0.0;
            }
          } else {
            _currentDistance = 0.0;
            _currentSpeed = 0.0;
          }
        });
        print('Status added: ${_currentExerciseStatuses.last.lat}, ${_currentExerciseStatuses.last.lon}, Total statuses: ${_currentExerciseStatuses.length}');
        print('Duration: $_currentDuration s, Distance: $_currentDistance m, Speed: $_currentSpeed m/s');
      }
    }, onError: (e) {
      print('Error getting location stream: $e');
    });
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
  }

  Future<void> _saveExerciseState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isExercising', _isExercising);
    await prefs.setInt('currentDuration', _currentDuration);
    await prefs.setDouble('currentDistance', _currentDistance);
    await prefs.setDouble('currentSpeed', _currentSpeed);
    await prefs.setString('currentExerciseStartTime', _currentExerciseStartTime?.toIso8601String() ?? '');

    final statusesJson = jsonEncode(_currentExerciseStatuses.map((s) => {
      'id': s.id,
      'lat': s.lat,
      'lon': s.lon,
      'time': s.time.toIso8601String(), 
    }).toList());
    await prefs.setString('currentExerciseStatuses', statusesJson);
    print('Exercise state saved. isExercising: $_isExercising, Duration: $_currentDuration, Distance: $_currentDistance, Statuses count: ${_currentExerciseStatuses.length}');
    print('Saved statuses JSON: $statusesJson');
  }

  Future<void> _saveLastKnownLocation(double lat, double lon) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings') 
            .doc('lastKnownLocation')
            .set({
          'latitude': lat,
          'longitude': lon,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Last known location saved: $lat, $lon');
      }
    } catch (e) {
      print('Error saving last known location: $e');
    }
  }

  Future<void> _loadLastKnownLocation() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('settings')
            .doc('lastKnownLocation')
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _lastKnownLocation = LatLng(data['latitude'], data['longitude']);
            _isMapInteracted = false; 
          });
          
          _mapController.move(
            _lastKnownLocation!,
            _mapController.camera.zoom,
          );
          print('Last known location loaded and map moved to: ${_lastKnownLocation!.latitude}, ${_lastKnownLocation!.longitude}');
        }
      }
    } catch (e) {
      print('Error loading last known location: $e');
    }
  }

  Future<void> _loadExerciseState() async {
    final prefs = await SharedPreferences.getInstance();
    final isExercising = prefs.getBool('isExercising') ?? false;
    final currentDistance = prefs.getDouble('currentDistance') ?? 0.0;
    final currentSpeed = prefs.getDouble('currentSpeed') ?? 0.0;
    final startTimeString = prefs.getString('currentExerciseStartTime');
    final statusesJson = prefs.getString('currentExerciseStatuses');

    if (isExercising && startTimeString != null && statusesJson != null && statusesJson.isNotEmpty) {
      final List<dynamic> decodedStatuses = jsonDecode(statusesJson);
      final List<Status> loadedStatuses = decodedStatuses.map((s) => Status(
        id: s['id'],
        lat: s['lat'],
        lon: s['lon'],
        time: DateTime.parse(s['time']), 
      )).toList();
      final loadedStartTime = DateTime.parse(startTimeString);
      final calculatedDuration = DateTime.now().difference(loadedStartTime).inSeconds;

      setState(() {
        _isExercising = isExercising;
        _currentDuration = calculatedDuration; 
        _currentDistance = currentDistance;
        _currentSpeed = currentSpeed;
        _currentExerciseStatuses = loadedStatuses;
        _currentExerciseStartTime = loadedStartTime;
      });

      if (_isExercising) {
        _startLocationTracking();
        _startStopwatch();
        print('Resumed exercise from saved state. Duration: $_currentDuration, Distance: $_currentDistance, Statuses count: ${_currentExerciseStatuses.length}, Loaded statuses: ${loadedStatuses.length}');
      }
    } else {
      print('No exercise state to load or exercise was not active.');
    }
  }

  void _calculateAndSaveExercise() async {
    if (_currentExerciseStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location data recorded for this exercise.')));
      return;
    }

    final startTime = _currentExerciseStatuses.first.time;
    final endTime = _currentExerciseStatuses.last.time;
    final duration = endTime.difference(startTime).inSeconds;

    double totalDistance = 0;
    for (int i = 0; i < _currentExerciseStatuses.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        _currentExerciseStatuses[i].lat,
        _currentExerciseStatuses[i].lon,
        _currentExerciseStatuses[i + 1].lat,
        _currentExerciseStatuses[i + 1].lon,
      );
    }

    final avgSpeed = duration > 0 ? totalDistance / duration : 0.0;

    final exercise = Exercise(
      id: _uuid.v4(),
      statuses: _currentExerciseStatuses,
      startTime: _currentExerciseStatuses.first.time, 
      duration: duration,
      distance: totalDistance,
      avgSpeed: avgSpeed,
    );

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('exercises')
            .doc(exercise.id)
            .set(exercise.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercise saved successfully!')));
        setState(() {
          _currentExerciseStatuses.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')));
      }
    } catch (e) {
      print('Error saving exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exercise: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use local theme state instead of global theme
    final textColor = _isLightMode ? Colors.black : Colors.white;

    return Scaffold(
      body: Stack( 
        children: [
          
          FlutterMap(
            mapController: _mapController, 
            options: MapOptions(
              initialCenter: _lastKnownLocation ?? LatLng(0, 0),
              initialZoom: 17,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _isMapInteracted = true; 
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isLightMode
                    ? 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
                    : 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              CurrentLocationLayer(),
              PolylineLayer(
                polylines: (_currentExerciseStatuses.isNotEmpty
                    ? [
                        Polyline<Object>(
                          points: _currentExerciseStatuses
                              .map((status) => LatLng(status.lat, status.lon))
                              .toList(),
                          color: Colors.blueAccent,
                          strokeWidth: 4.0,
                        ),
                      ]
                    : []).cast<Polyline<Object>>(),
              ),
            ],
          ),
          
          // Theme toggle button
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: Icon(
                  _isLightMode ? Icons.dark_mode : Icons.light_mode,
                  color: textColor,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _isLightMode = !_isLightMode;
                  });
                  // Notify parent about theme change
                  widget.onThemeChanged?.call(_isLightMode);
                },
              ),
            ),
          ),

          Positioned( 
            bottom: 132.0,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  Text(
                    '${(_currentDuration ~/ 3600).toString().padLeft(2, '0')}:${((_currentDuration % 3600) ~/ 60).toString().padLeft(2, '0')}:${(_currentDuration % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 24, color: textColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16), 

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      
                      Expanded(
                        child: Text(
                          '${_currentDistance.toStringAsFixed(2)} m',
                          style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center, 
                        ),
                      ),

                      
                      Expanded(
                        child: Center( 
                          child: Container(
                            width: 96, 
                            height: 96, 
                            decoration: BoxDecoration(
                              color: MyColors.accent,
                              borderRadius: BorderRadius.circular(48), 
                            ),
                            child: _isExercising
                                ? IconButton(
                                    icon: Icon(MingCuteIcons.mgc_pause_line, size: 48, color: textColor), 
                                    onPressed: _stopExercise,
                                  )
                                : IconButton(
                                    icon: Icon(MingCuteIcons.mgc_play_line, size: 48, color: textColor), 
                                    onPressed: _startExercise,
                                  ),
                          ),
                        ),
                      ),

                      
                      Expanded(
                        child: Text(
                          '${_currentSpeed.toStringAsFixed(2)} m/s',
                          style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center, 
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
