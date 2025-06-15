import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseStepData {
  final String userId;
  final int steps;
  final double caloriesBurned;
  final double distance;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  FirebaseStepData({
    required this.userId,
    required this.steps,
    required this.caloriesBurned,
    required this.distance,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'steps': steps,
      'caloriesBurned': caloriesBurned,
      'distance': distance,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata ?? {},
    };
  }

  factory FirebaseStepData.fromMap(Map<String, dynamic> map) {
    return FirebaseStepData(
      userId: map['userId'] as String,
      steps: map['steps'] as int,
      caloriesBurned: map['caloriesBurned'] as double,
      distance: map['distance'] as double,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
} 