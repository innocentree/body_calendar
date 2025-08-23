import 'package:uuid/uuid.dart';

class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final double? height; // cm
  final double? weight; // kg
  final String? profileImageUrl;
  final List<String> goals;
  final List<String> preferredWorkoutTypes;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    String? id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.height,
    this.weight,
    this.profileImageUrl,
    List<String>? goals,
    List<String>? preferredWorkoutTypes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        goals = goals ?? [],
        preferredWorkoutTypes = preferredWorkoutTypes ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserProfile copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? birthDate,
    String? gender,
    double? height,
    double? weight,
    String? profileImageUrl,
    List<String>? goals,
    List<String>? preferredWorkoutTypes,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      goals: goals ?? this.goals,
      preferredWorkoutTypes: preferredWorkoutTypes ?? this.preferredWorkoutTypes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'profileImageUrl': profileImageUrl,
      'goals': goals,
      'preferredWorkoutTypes': preferredWorkoutTypes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
      profileImageUrl: json['profileImageUrl'],
      goals: List<String>.from(json['goals'] ?? []),
      preferredWorkoutTypes:
          List<String>.from(json['preferredWorkoutTypes'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // BMI 계산
  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  // BMI 상태 판단
  String? get bmiStatus {
    if (bmi == null) return null;
    if (bmi! < 18.5) return '저체중';
    if (bmi! < 25) return '정상';
    if (bmi! < 30) return '과체중';
    return '비만';
  }

  // 나이 계산
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var age = now.year - birthDate!.year;
    final monthDiff = now.month - birthDate!.month;
    if (monthDiff < 0 ||
        (monthDiff == 0 && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
} 