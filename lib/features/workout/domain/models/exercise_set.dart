class ExerciseSet {
  final double weight;
  final int reps;
  final Duration restTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final double? bodyWeight;
  final double? assistedWeight;
  final bool isLbs;

  ExerciseSet({
    required this.weight,
    required this.reps,
    this.restTime = const Duration(minutes: 1),
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.bodyWeight,
    this.assistedWeight,
    this.isLbs = false,
  });

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'reps': reps,
        'restTime': restTime.inSeconds,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isCompleted': isCompleted,
        'bodyWeight': bodyWeight,
        'assistedWeight': assistedWeight,
        'isLbs': isLbs,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        weight: (json['weight'] is int)
            ? (json['weight'] as int).toDouble()
            : (json['weight'] is double)
                ? json['weight']
                : double.tryParse(json['weight'].toString()) ?? 0.0,
        reps: json['reps'],
        restTime: Duration(seconds: json['restTime']),
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'])
            : null,
        endTime:
            json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        isCompleted: json['isCompleted'],
        bodyWeight: (json['bodyWeight'] is int)
            ? (json['bodyWeight'] as int).toDouble()
            : (json['bodyWeight'] as double?),
        assistedWeight: (json['assistedWeight'] is int)
            ? (json['assistedWeight'] as int).toDouble()
            : (json['assistedWeight'] as double?),
        isLbs: json['isLbs'] ?? false,
      );

  ExerciseSet copyWith({
    double? weight,
    int? reps,
    Duration? restTime,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    double? bodyWeight,
    double? assistedWeight,
    bool? isLbs,
  }) {
    return ExerciseSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      assistedWeight: assistedWeight ?? this.assistedWeight,
      isLbs: isLbs ?? this.isLbs,
    );
  }
}
