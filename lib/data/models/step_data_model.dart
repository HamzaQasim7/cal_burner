class StepData {
  final DateTime timestamp;
  final int stepCount;
  final int stepsSinceLastUpdate;

  StepData({
    required this.timestamp,
    required this.stepCount,
    required this.stepsSinceLastUpdate,
  });

  factory StepData.fromJson(Map<String, dynamic> json) {
    return StepData(
      timestamp: DateTime.parse(json['timestamp']),
      stepCount: json['stepCount'] ?? 0,
      stepsSinceLastUpdate: json['stepsSinceLastUpdate'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'stepCount': stepCount,
      'stepsSinceLastUpdate': stepsSinceLastUpdate,
    };
  }
}
