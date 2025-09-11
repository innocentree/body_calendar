import 'package:uuid/uuid.dart';

class Exercise {
  final String id;
  final String name;
  final String imagePath;
  final int sets;
  final double weight;
  final String description;
  final String equipment;
  final List<Exercise> variations;
  final bool isCustom;
  final String? bodyPart;
  final bool needsWeight;

  Exercise({
    String? id,
    required this.name,
    required this.imagePath,
    required this.sets,
    required this.weight,
    required this.description,
    this.equipment = '',
    this.variations = const [],
    this.isCustom = false,
    this.bodyPart,
    this.needsWeight = true,
  }) : id = id ?? Uuid().v4();

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String?,
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
      isCustom: json['isCustom'] as bool? ?? false,
      bodyPart: json['bodyPart'] as String?,
      needsWeight: json['needsWeight'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'sets': sets,
      'weight': weight,
      'description': description,
      'equipment': equipment,
      'variations': variations.map((e) => e.toJson()).toList(),
      'isCustom': isCustom,
      'bodyPart': bodyPart,
      'needsWeight': needsWeight,
    };
  }
}