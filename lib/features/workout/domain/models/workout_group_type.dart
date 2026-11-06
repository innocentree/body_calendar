enum WorkoutGroupBehavior { setWorkout }

abstract final class WorkoutGroupType {
  static const String setWorkout = 'set';
  static const String legacySuperset = 'superset';
  static const String legacyCompound = 'compound';

  static WorkoutGroupBehavior behaviorFor(String? storedValue) {
    switch (storedValue) {
      case setWorkout:
      case legacySuperset:
      case legacyCompound:
      default:
        return WorkoutGroupBehavior.setWorkout;
    }
  }

  static String statisticsKey(String? _) => setWorkout;
}
