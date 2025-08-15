import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String taskName;
  
  @HiveField(1)
  final String taskType;
  
  @HiveField(2)
  final int xpReward;
  
  @HiveField(3)
  final int completedAtLevel;
  
  @HiveField(4)
  final DateTime completedAt;
  
  @HiveField(5)
  final String id;

  @HiveField(6)
  final String normalizedTaskType; // Pre-computed normalized type
  
  @HiveField(7)
  final int difficulty; // foruture implementation
  
  @HiveField(8)
  final Map<String, dynamic>? metadata; // Extensible metadata

  TaskModel({
    required this.taskName,
    required this.taskType,
    required this.xpReward,
    required this.completedAtLevel,
    required this.completedAt,
    required this.id,
    String? normalizedTaskType,
    this.difficulty = 1,
    this.metadata,
  }) : normalizedTaskType = normalizedTaskType ?? _normalizeTaskType(taskType);

  static String _normalizeTaskType(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'strength':
      case 'physical':
      case 'workout':
        return 'Strength';
      case 'agility':
      case 'speed':
      case 'sports':
        return 'Agility';
      case 'endurance':
      case 'cardio':
      case 'stamina':
        return 'Endurance';
      case 'vitality':
      case 'health':
      case 'nutrition':
        return 'Vitality';
      case 'intelligence':
      case 'study':
      case 'brain':
      case 'mental':
        return 'Intelligence';
      default:
        return 'Intelligence';
    }
  }


  bool isCompletedAtLevel(int level) => completedAtLevel == level;
  bool isCompletedBetweenLevels(int fromLevel, int toLevel) => 
      completedAtLevel >= fromLevel && completedAtLevel < toLevel;
  bool isOfType(String type) => normalizedTaskType == type;

  Map<String, dynamic> toJson() => {
    'taskName': taskName,
    'taskType': taskType,
    'xpReward': xpReward,
    'completedAtLevel': completedAtLevel,
    'completedAt': completedAt.toIso8601String(),
    'id': id,
    'normalizedTaskType': normalizedTaskType,
    'difficulty': difficulty,
    'metadata': metadata,
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    taskName: json['taskName'],
    taskType: json['taskType'],
    xpReward: json['xpReward'],
    completedAtLevel: json['completedAtLevel'],
    completedAt: DateTime.parse(json['completedAt']),
    id: json['id'],
    normalizedTaskType: json['normalizedTaskType'],
    difficulty: json['difficulty'] ?? 1,
    metadata: json['metadata'],
  );
}
