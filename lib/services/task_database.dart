import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

class TaskDatabase {
  static const String _boxName = 'hunterTasks';
  static Box<TaskModel>? _taskBox;
  
  // Initialize Hive and open task box
  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskModelAdapter());
    _taskBox = await Hive.openBox<TaskModel>(_boxName);
  }
  
  static Box<TaskModel> get taskBox {
    if (_taskBox == null || !_taskBox!.isOpen) {
      throw Exception('Task box not initialized. Call initialize() first.');
    }
    return _taskBox!;
  }
  
  // Add completed task
  static Future<void> addCompletedTask(TaskModel task) async {
    await taskBox.put(task.id, task);
  }
  
  // Get tasks completed between level range (for stat calculation)
  static List<TaskModel> getTasksBetweenLevels(int fromLevel, int toLevel) {
    return taskBox.values
        .where((task) => task.completedAtLevel >= fromLevel && task.completedAtLevel < toLevel)
        .toList();
  }
  
  // Get tasks by type within level range
  static List<TaskModel> getTasksByTypeInRange(String taskType, int fromLevel, int toLevel) {
    return taskBox.values
        .where((task) => 
            task.taskType == taskType && 
            task.completedAtLevel >= fromLevel && 
            task.completedAtLevel < toLevel)
        .toList();
  }
  
  // Get all completed tasks
  static List<TaskModel> getAllTasks() {
    return taskBox.values.toList();
  }
  
  // Delete task
  static Future<void> deleteTask(String taskId) async {
    await taskBox.delete(taskId);
  }
  
  // Clear all tasks (for testing)
  static Future<void> clearAllTasks() async {
    await taskBox.clear();
  }
}
