class WorkoutStatistics {
  final int totalWorkouts;
  final int totalDuration; // 분 단위
  final int totalExercises;
  final int totalSets;
  final double totalWeight; // kg
  final Map<String, int> exerciseCounts;
  final Map<String, double> exerciseWeights;
  final Map<String, int> exerciseDurations;
  final List<DailyStatistics> dailyStats;
  final List<WeeklyStatistics> weeklyStats;
  final List<MonthlyStatistics> monthlyStats;

  WorkoutStatistics({
    required this.totalWorkouts,
    required this.totalDuration,
    required this.totalExercises,
    required this.totalSets,
    required this.totalWeight,
    required this.exerciseCounts,
    required this.exerciseWeights,
    required this.exerciseDurations,
    required this.dailyStats,
    required this.weeklyStats,
    required this.monthlyStats,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalDuration': totalDuration,
      'totalExercises': totalExercises,
      'totalSets': totalSets,
      'totalWeight': totalWeight,
      'exerciseCounts': exerciseCounts,
      'exerciseWeights': exerciseWeights,
      'exerciseDurations': exerciseDurations,
      'dailyStats': dailyStats.map((e) => e.toJson()).toList(),
      'weeklyStats': weeklyStats.map((e) => e.toJson()).toList(),
      'monthlyStats': monthlyStats.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutStatistics.fromJson(Map<String, dynamic> json) {
    return WorkoutStatistics(
      totalWorkouts: json['totalWorkouts'],
      totalDuration: json['totalDuration'],
      totalExercises: json['totalExercises'],
      totalSets: json['totalSets'],
      totalWeight: json['totalWeight'],
      exerciseCounts: Map<String, int>.from(json['exerciseCounts']),
      exerciseWeights: Map<String, double>.from(json['exerciseWeights']),
      exerciseDurations: Map<String, int>.from(json['exerciseDurations']),
      dailyStats: (json['dailyStats'] as List)
          .map((e) => DailyStatistics.fromJson(e))
          .toList(),
      weeklyStats: (json['weeklyStats'] as List)
          .map((e) => WeeklyStatistics.fromJson(e))
          .toList(),
      monthlyStats: (json['monthlyStats'] as List)
          .map((e) => MonthlyStatistics.fromJson(e))
          .toList(),
    );
  }
}

class DailyStatistics {
  final DateTime date;
  final int workoutCount;
  final int totalDuration;
  final int exerciseCount;
  final int setCount;
  final double totalWeight;
  final Map<String, int> exerciseCounts;
  final Map<String, double> exerciseWeights;

  DailyStatistics({
    required this.date,
    required this.workoutCount,
    required this.totalDuration,
    required this.exerciseCount,
    required this.setCount,
    required this.totalWeight,
    required this.exerciseCounts,
    required this.exerciseWeights,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'workoutCount': workoutCount,
      'totalDuration': totalDuration,
      'exerciseCount': exerciseCount,
      'setCount': setCount,
      'totalWeight': totalWeight,
      'exerciseCounts': exerciseCounts,
      'exerciseWeights': exerciseWeights,
    };
  }

  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    return DailyStatistics(
      date: DateTime.parse(json['date']),
      workoutCount: json['workoutCount'],
      totalDuration: json['totalDuration'],
      exerciseCount: json['exerciseCount'],
      setCount: json['setCount'],
      totalWeight: json['totalWeight'],
      exerciseCounts: Map<String, int>.from(json['exerciseCounts']),
      exerciseWeights: Map<String, double>.from(json['exerciseWeights']),
    );
  }
}

class WeeklyStatistics {
  final DateTime startDate;
  final DateTime endDate;
  final int workoutCount;
  final int totalDuration;
  final int exerciseCount;
  final int setCount;
  final double totalWeight;
  final Map<String, int> exerciseCounts;
  final Map<String, double> exerciseWeights;
  final List<DailyStatistics> dailyStats;

  WeeklyStatistics({
    required this.startDate,
    required this.endDate,
    required this.workoutCount,
    required this.totalDuration,
    required this.exerciseCount,
    required this.setCount,
    required this.totalWeight,
    required this.exerciseCounts,
    required this.exerciseWeights,
    required this.dailyStats,
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'workoutCount': workoutCount,
      'totalDuration': totalDuration,
      'exerciseCount': exerciseCount,
      'setCount': setCount,
      'totalWeight': totalWeight,
      'exerciseCounts': exerciseCounts,
      'exerciseWeights': exerciseWeights,
      'dailyStats': dailyStats.map((e) => e.toJson()).toList(),
    };
  }

  factory WeeklyStatistics.fromJson(Map<String, dynamic> json) {
    return WeeklyStatistics(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      workoutCount: json['workoutCount'],
      totalDuration: json['totalDuration'],
      exerciseCount: json['exerciseCount'],
      setCount: json['setCount'],
      totalWeight: json['totalWeight'],
      exerciseCounts: Map<String, int>.from(json['exerciseCounts']),
      exerciseWeights: Map<String, double>.from(json['exerciseWeights']),
      dailyStats: (json['dailyStats'] as List)
          .map((e) => DailyStatistics.fromJson(e))
          .toList(),
    );
  }
}

class MonthlyStatistics {
  final DateTime year;
  final int month;
  final int workoutCount;
  final int totalDuration;
  final int exerciseCount;
  final int setCount;
  final double totalWeight;
  final Map<String, int> exerciseCounts;
  final Map<String, double> exerciseWeights;
  final List<WeeklyStatistics> weeklyStats;

  MonthlyStatistics({
    required this.year,
    required this.month,
    required this.workoutCount,
    required this.totalDuration,
    required this.exerciseCount,
    required this.setCount,
    required this.totalWeight,
    required this.exerciseCounts,
    required this.exerciseWeights,
    required this.weeklyStats,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year.toIso8601String(),
      'month': month,
      'workoutCount': workoutCount,
      'totalDuration': totalDuration,
      'exerciseCount': exerciseCount,
      'setCount': setCount,
      'totalWeight': totalWeight,
      'exerciseCounts': exerciseCounts,
      'exerciseWeights': exerciseWeights,
      'weeklyStats': weeklyStats.map((e) => e.toJson()).toList(),
    };
  }

  factory MonthlyStatistics.fromJson(Map<String, dynamic> json) {
    return MonthlyStatistics(
      year: DateTime.parse(json['year']),
      month: json['month'],
      workoutCount: json['workoutCount'],
      totalDuration: json['totalDuration'],
      exerciseCount: json['exerciseCount'],
      setCount: json['setCount'],
      totalWeight: json['totalWeight'],
      exerciseCounts: Map<String, int>.from(json['exerciseCounts']),
      exerciseWeights: Map<String, double>.from(json['exerciseWeights']),
      weeklyStats: (json['weeklyStats'] as List)
          .map((e) => WeeklyStatistics.fromJson(e))
          .toList(),
    );
  }
} 