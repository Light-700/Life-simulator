import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String taskName;
  
  @HiveField(1)
  final String taskType; // 'Strength', 'Intelligence', etc.
  
  @HiveField(2)
  final int xpReward;
  
  @HiveField(3)
  final int completedAtLevel; // Level when task was completed
  
  @HiveField(4)
  final DateTime completedAt;
  
  @HiveField(5)
  final String id; // Unique identifier
  
  TaskModel({
    required this.taskName,
    required this.taskType,
    required this.xpReward,
    required this.completedAtLevel,
    required this.completedAt,
    required this.id,
  });
}
