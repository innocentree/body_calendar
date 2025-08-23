class Exercise {
  final String name;
  final String imagePath;
  final int sets;
  final double weight;
  final String description;
  final String equipment;
  final List<Exercise> variations;

  Exercise({
    required this.name,
    required this.imagePath,
    required this.sets,
    required this.weight,
    required this.description,
    this.equipment = '',
    this.variations = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      sets: json['sets'] as int,
      weight: (json['weight'] is int) 
          ? (json['weight'] as int).toDouble()
          : json['weight'] as double,
      description: json['description'] as String,
      equipment: json['equipment'] as String? ?? '',
      variations: json['variations'] != null
          ? (json['variations'] as List<dynamic>)
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imagePath': imagePath,
      'sets': sets,
      'weight': weight,
      'description': description,
      'equipment': equipment,
      'variations': variations.map((e) => e.toJson()).toList(),
    };
  }
} 