import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isEmailVerified;

  // Profile fields
  final int? age;
  final double? height;
  final double? weight;
  final double? bodyFatPercentage;
  final String? gender;
  final String? location;
  final double? impScore;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    this.isEmailVerified = false,
    this.age,
    this.height,
    this.weight,
    this.bodyFatPercentage,
    this.gender,
    this.location,
    this.impScore,
  });

  /// Creates a new instance with default values for required fields
  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      name: '',
      createdAt: DateTime.now(),
    );
  }

  /// Creates a new instance from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      age: json['age'] as int?,
      height: json['height'] as double?,
      weight: json['weight'] as double?,
      bodyFatPercentage: json['bodyFatPercentage'] as double?,
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      impScore: json['impScore'] as double?,
    );
  }

  /// Converts the instance to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'age': age,
      'height': height,
      'weight': weight,
      'bodyFatPercentage': bodyFatPercentage,
      'gender': gender,
      'location': location,
      'impScore': impScore,
    };
  }

  /// Creates a copy of this instance with the given fields replaced with new values
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    DateTime? createdAt,
    bool? isEmailVerified,
    int? age,
    double? height,
    double? weight,
    double? bodyFatPercentage,
    String? gender,
    String? location,
    double? impScore,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      impScore: impScore ?? this.impScore,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        createdAt,
        isEmailVerified,
        age,
        height,
        weight,
        bodyFatPercentage,
        gender,
        location,
        impScore,
      ];

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, photoUrl: $photoUrl, '
        'createdAt: $createdAt, isEmailVerified: $isEmailVerified, '
        'age: $age, height: $height, weight: $weight, '
        'bodyFatPercentage: $bodyFatPercentage, gender: $gender, '
        'location: $location, impScore: $impScore)';
  }

  // Calculate IMP Score based on user metrics
  double calculateImpScore() {
    double score = 0.0;
    
    // Base score for having a profile
    score += 10.0;
    
    // Add points for completed profile information
    if (age != null) score += 5.0;
    if (height != null) score += 5.0;
    if (weight != null) score += 5.0;
    if (bodyFatPercentage != null) score += 5.0;
    if (gender != null) score += 5.0;
    if (location != null) score += 5.0;
    
    // Add points for email verification
    if (isEmailVerified) score += 10.0;
    
    // Normalize score to 3 decimal places
    return double.parse(score.toStringAsFixed(3));
  }

  // Update IMP Score
  UserModel updateImpScore() {
    return copyWith(impScore: calculateImpScore());
  }
}
