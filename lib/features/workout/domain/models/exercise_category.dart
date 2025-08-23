class ExerciseCategory {
  final String name;
  final String description;
  final List<Exercise> exercises;

  ExerciseCategory({
    required this.name,
    required this.description,
    required this.exercises,
  });
}

class Exercise {
  final String name;
  final String imagePath;
  final int sets;
  final double weight;
  final String description;

  Exercise({
    required this.name,
    required this.imagePath,
    required this.sets,
    required this.weight,
    required this.description,
  });
} 