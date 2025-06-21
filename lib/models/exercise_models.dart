import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Status {
  final String id;
  final double lat;
  final double lon;
  final DateTime time;

  Status({
    required this.id,
    required this.lat,
    required this.lon,
    required this.time,
  });

  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      id: map['id'],
      lat: map['lat'],
      lon: map['lon'],
      time: (map['time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lat': lat,
      'lon': lon,
      'time': Timestamp.fromDate(time),
    };
  }
}

class Exercise {
  final String id;
  final List<Status> statuses;
  final DateTime startTime; 
  final int duration; 
  final double distance; 
  final double avgSpeed; 

  Exercise({
    required this.id,
    required this.statuses,
    required this.startTime, 
    required this.duration,
    required this.distance,
    required this.avgSpeed,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      statuses: (map['statuses'] as List)
          .map((statusMap) => Status.fromMap(statusMap))
          .toList(),
      startTime: (map['start_time'] as Timestamp).toDate(), 
      duration: map['duration'],
      distance: map['distance'],
      avgSpeed: map['avg_speed'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'statuses': statuses.map((status) => status.toMap()).toList(),
      'start_time': Timestamp.fromDate(startTime), 
      'duration': duration,
      'distance': distance,
      'avg_speed': avgSpeed,
    };
  }
}
