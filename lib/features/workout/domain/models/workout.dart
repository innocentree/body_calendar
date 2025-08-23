class Exercise {
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final int intensity;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.intensity,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'intensity': intensity,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: json['weight'] as double,
      intensity: json['intensity'] as int,
    );
  }
}

class Workout {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final int duration;
  final DateTime date;

  Workout({
    required this.id,
    required this.name,
    required this.exercises,
    required this.duration,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'duration': duration,
      'date': date.toIso8601String(),
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      duration: json['duration'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }
} 