// lib/models/daily_activity.dart
class DailyActivity {
  final String id;
  final String userId;
  final DateTime date;
  final int steps;
  final double caloriesBurned;
  final double distance;
  final int activeMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyActivity({
    required this.id,
    required this.userId,
    required this.date,
    required this.steps,
    required this.caloriesBurned,
    required this.distance,
    required this.activeMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      steps: json['steps'] ?? 0,
      caloriesBurned: (json['caloriesBurned'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      activeMinutes: json['activeMinutes'] ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'steps': steps,
      'caloriesBurned': caloriesBurned,
      'distance': distance,
      'activeMinutes': activeMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DailyActivity copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? steps,
    double? caloriesBurned,
    double? distance,
    int? activeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distance: distance ?? this.distance,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get dateString => "${date.day}/${date.month}/${date.year}";

  double get stepGoalProgress => steps / 10000.0; // Assuming 10k step goal
}
