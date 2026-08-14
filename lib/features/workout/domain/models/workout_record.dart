class WorkoutRecord {
  final int id;
  final String name;
  final String imagePath;
  final int sets;
  final double weight;
  final DateTime timestamp;
  final int sessionIndex;
  final String equipment;
  final String? bodyPart;
  final String? groupId;
  final String? groupType;
  final String? groupLabel;
  final int? groupOrder;

  WorkoutRecord({
    required this.id,
    required this.name,
    this.imagePath = 'assets/images/default_exercise.png',
    required this.sets,
    required this.weight,
    required this.timestamp,
    required this.sessionIndex,
    this.equipment = '',
    this.bodyPart,
    this.groupId,
    this.groupType,
    this.groupLabel,
    this.groupOrder,
  });

  bool get isGrouped => groupId != null && groupId!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'sets': sets,
        'weight': weight,
        'timestamp': timestamp.toIso8601String(),
        'sessionIndex': sessionIndex,
        'equipment': equipment,
        'bodyPart': bodyPart,
        'groupId': groupId,
        'groupType': groupType,
        'groupLabel': groupLabel,
        'groupOrder': groupOrder,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        id: json['id'],
        name: json['name'],
        imagePath: json['imagePath'],
        sets: json['sets'],
        weight: json['weight'],
        timestamp: DateTime.parse(json['timestamp']),
        sessionIndex: json['sessionIndex'],
        equipment: json['equipment'] ?? '',
        bodyPart: json['bodyPart'],
        groupId: json['groupId'],
        groupType: json['groupType'],
        groupLabel: json['groupLabel'],
        groupOrder: json['groupOrder'],
      );
}
