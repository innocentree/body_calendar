import 'package:uuid/uuid.dart';

class Workout {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final int duration; // 분 단위
  final List<Exercise> exercises;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Workout({
    String? id,
    required this.name,
    required this.description,
    required this.date,
    required this.duration,
    required this.exercises,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Workout copyWith({
    String? name,
    String? description,
    DateTime? date,
    int? duration,
    List<Exercise>? exercises,
    String? notes,
  }) {
    return Workout(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'duration': duration,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      duration: json['duration'],
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final String category;
  final List<Set> sets;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    String? id,
    required this.name,
    required this.category,
    required this.sets,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Exercise copyWith({
    String? name,
    String? category,
    List<Set>? sets,
    String? notes,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sets': sets.map((e) => e.toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      sets: (json['sets'] as List).map((e) => Set.fromJson(e)).toList(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Set {
  final String id;
  final int setNumber;
  final int reps;
  final double weight;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Set({
    String? id,
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Set copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    bool? isCompleted,
  }) {
    return Set(
      id: id,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Set.fromJson(Map<String, dynamic> json) {
    return Set(
      id: json['id'],
      setNumber: json['setNumber'],
      reps: json['reps'],
      weight: json['weight'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
} 