import 'package:hive/hive.dart';
import 'task_model.dart';

part 'quest_model.g.dart';

@HiveType(typeId: 1) // Using typeId 1 since TaskModel uses 0
class QuestModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String questType; // 'ongoing', 'completed', 'upcoming', 'daily'
  
  @HiveField(4)
  final String difficulty; // 'E', 'D', 'C', 'B', 'A', 'S'
  
  @HiveField(5)
  final List<String> objectives;
  
  @HiveField(6)
  final Map<String, int> rewards; // XP and stat rewards
  
  @HiveField(7)
  final String category; // 'main', 'secondary', 'side', 'mandatory'
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final DateTime? completedAt;
  
  @HiveField(10)
  final DateTime expiresAt;
  
  @HiveField(11)
  final bool isCompleted;
  
  @HiveField(12)
  final double progress;
  
  @HiveField(13)
  final int unlockLevel; // Level required to unlock
  
  @HiveField(14)
  final Map<String, dynamic>? metadata; // Extensible for future features
  
  @HiveField(15)
  final bool isMandatory; // For daily quests
  
  @HiveField(16)
  final int penaltyAmount; // Stat reduction if failed
  
  @HiveField(17)
  final String penaltyType; // 'all_stats', 'strength', etc.
  
  QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.questType,
    required this.difficulty,
    required this.objectives,
    required this.rewards,
    required this.category,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
    this.isCompleted = false,
    this.progress = 0.0,
    this.unlockLevel = 1,
    this.metadata,
    this.isMandatory = false,
    this.penaltyAmount = 0,
    this.penaltyType = 'none',
  });
  
  // Convert completed quest to TaskModel for existing stat system integration
  TaskModel toTaskModel(int completedAtLevel) {
    return TaskModel(
      id: id,
      taskName: title,
      taskType: _getTaskTypeFromRewards(),
      xpReward: rewards['xp'] ?? 0,
      completedAtLevel: completedAtLevel,
      completedAt: completedAt ?? DateTime.now(),
      difficulty: _getDifficultyAsInt(),
      metadata: {
        'originalQuestId': id,
        'questCategory': category,
        'questDifficulty': difficulty,
        'questType': questType,
        'isMandatory': isMandatory,
        ...?metadata,
      },
    );
  }
  
  // Determine primary stat boost from rewards to match TaskModel system
  String _getTaskTypeFromRewards() {
    if (rewards.isEmpty) return 'intelligence';
    
    int maxReward = 0;
    String primaryType = 'intelligence';
    
    // Check each stat reward (excluding XP)
    rewards.forEach((stat, value) {
      if (stat != 'xp' && value > maxReward) {
        maxReward = value;
        primaryType = stat;
      }
    });
    
    return primaryType;
  }
  
  // Convert difficulty letter to int for TaskModel compatibility
  int _getDifficultyAsInt() {
    switch (difficulty) {
      case 'E': return 1;
      case 'D': return 2;
      case 'C': return 3;
      case 'B': return 4;
      case 'A': return 5;
      case 'S': return 6;
      default: return 1;
    }
  }
  
  // Check if quest has expired
  bool get hasExpired => DateTime.now().isAfter(expiresAt);
  
  // Check if quest is available for current level
  bool isAvailableForLevel(int level) => level >= unlockLevel;
  
  // Calculate time remaining
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }
  
  // Get formatted time remaining
  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Expired';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
  
  // Create a copy with updated values
  QuestModel copyWith({
    String? questType,
    bool? isCompleted,
    double? progress,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return QuestModel(
      id: id,
      title: title,
      description: description,
      questType: questType ?? this.questType,
      difficulty: difficulty,
      objectives: objectives,
      rewards: rewards,
      category: category,
      createdAt: createdAt,
      expiresAt: expiresAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      unlockLevel: unlockLevel,
      metadata: metadata ?? this.metadata,
      isMandatory: isMandatory,
      penaltyAmount: penaltyAmount,
      penaltyType: penaltyType,
    );
  }
  
  // JSON serialization for debugging/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questType': questType,
      'difficulty': difficulty,
      'objectives': objectives,
      'rewards': rewards,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isCompleted': isCompleted,
      'progress': progress,
      'unlockLevel': unlockLevel,
      'metadata': metadata,
      'isMandatory': isMandatory,
      'penaltyAmount': penaltyAmount,
      'penaltyType': penaltyType,
    };
  }
  
  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      questType: json['questType'] ?? 'ongoing',
      difficulty: json['difficulty'] ?? 'E',
      objectives: List<String>.from(json['objectives'] ?? []),
      rewards: Map<String, int>.from(json['rewards'] ?? {}),
      category: json['category'] ?? 'main',
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      expiresAt: DateTime.parse(json['expiresAt']),
      isCompleted: json['isCompleted'] ?? false,
      progress: (json['progress'] ?? 0.0).toDouble(),
      unlockLevel: json['unlockLevel'] ?? 1,
      metadata: json['metadata'],
      isMandatory: json['isMandatory'] ?? false,
      penaltyAmount: json['penaltyAmount'] ?? 0,
      penaltyType: json['penaltyType'] ?? 'none',
    );
  }
}

// Daily Quest subclass for mandatory daily tasks (Sung Jin-Woo style)
@HiveType(typeId: 2)
class DailyQuest extends QuestModel {
  DailyQuest({
    required String id,
    required String title,
    required String description,
    required Map<String, int> rewards,
    required List<String> objectives,
    bool isMandatory = true,
    int penaltyAmount = 1,
    String penaltyType = 'all_stats',
    DateTime? lastResetDate,
  }) : super(
          id: id,
          title: title,
          description: description,
          questType: 'daily',
          difficulty: 'E', // Daily quests start easy but can scale
          objectives: objectives,
          rewards: rewards,
          category: 'mandatory',
          createdAt: DateTime.now(),
          expiresAt: _getNextMidnight(),
          isMandatory: isMandatory,
          penaltyAmount: penaltyAmount,
          penaltyType: penaltyType,
        );
  
  static DateTime _getNextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }
}
