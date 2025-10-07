// lib/services/gemini_quest_service.dart - FULLY CORRECTED VERSION

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quest_model.dart';
import 'quest_database_hive.dart';
import 'dart:convert';
import 'dart:math';

class GeminiQuestService {
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      print('❌ Error: GEMINI_API_KEY not found in .env file');
      print('📝 Please add GEMINI_API_KEY=your_key_here to your .env file');
      return '';
    }
    return key;
  }

  late final GenerativeModel _model;
  bool _isConfigured = false;

  GeminiQuestService() {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      _isConfigured = true;
      print('✅ Gemini AI service initialized successfully');
    } else {
      print('⚠️ Gemini AI service not configured - missing API key');
      _isConfigured = false;
    }
  }

  // Check if service is properly configured
  bool get isConfigured => _isConfigured;

  // Generate and store daily quests
  Future<void> generateAndStoreDailyQuests() async {
    try {
      await QuestDatabaseHive.cleanupExpiredQuests();
      final existingQuests = QuestDatabaseHive.getActiveQuests();
      if (existingQuests.length >= 3) return;

      final userProfile = await _getUserProfileFromPrefs();
      final newQuests = await _generateQuestsFromAI(userProfile);

      for (final quest in newQuests) {
        await QuestDatabaseHive.addQuest(quest);
      }
    } catch (e) {
      print('Error generating quests: $e');
      await _generateDefaultQuests();
    }
  }

  // Get user profile from SharedPreferences
  Future<Map<String, dynamic>> _getUserProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? 'Hunter',
      'fitnessGoal': prefs.getString('fitnessGoal') ?? 'Overall Development',
      'hunterClass': prefs.getString('Class') ?? 'E-rank',
      'currentLevel': prefs.getInt('level') ?? 1,
      'age': prefs.getString('age') ?? '25',
      'weight': prefs.getString('weight') ?? '70',
      'job': prefs.getString('Job') ?? 'Student',
      'strength': prefs.getInt('strengthStat') ?? 30,
      'agility': prefs.getInt('agilityStat') ?? 30,
      'endurance': prefs.getInt('enduranceStat') ?? 30,
      'vitality': prefs.getInt('vitalityStat') ?? 30,
      'intelligence': prefs.getInt('intelligenceStat') ?? 30,
      'totalStats': prefs.getInt('totalStats') ?? 150,
    };
  }

  // Generate quests from AI
  Future<List<QuestModel>> _generateQuestsFromAI(Map<String, dynamic> profile) async {
    if (!_isConfigured) {
      print('⚠️ Gemini AI not configured, using default quests');
      return [];
    }

    try {
      final prompt = _buildSystemPrompt(profile);
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        print('⚠️ Empty response from Gemini AI');
        return [];
      }

      final quests = _parseQuestsFromAIResponse(response.text!);
      if (quests.isEmpty) {
        print('⚠️ No valid quests parsed from AI response');
      } else {
        print('✅ Successfully parsed ${quests.length} quests from AI');
      }

      return quests;
    } catch (e) {
      print('❌ Error generating quests from AI: $e');
      return [];
    }
  }

  String _buildSystemPrompt(Map<String, dynamic> profile) {
    return '''
You are the Shadow Monarch's System from Solo Leveling. Generate exactly 3 real-world daily quests for this hunter:

Hunter Profile:
- Name: ${profile['username']}
- Current Class: ${profile['hunterClass']}
- Level: ${profile['currentLevel']}
- Primary Goal: ${profile['fitnessGoal']}
- Occupation: ${profile['job']}
- Age: ${profile['age']} years
- Current Stats: STR:${profile['strength']}, AGI:${profile['agility']}, END:${profile['endurance']}, VIT:${profile['vitality']}, INT:${profile['intelligence']}

Quest Requirements:
- Real-world activities only (no fantasy elements like "kill goblins")
- Activities should be specific and measurable
- Adapt difficulty to current class level (${profile['hunterClass']})
- 70% focus on primary goal: ${profile['fitnessGoal']}
- 30% balanced across other stats for complete development
- Consider user's occupation: ${profile['job']}

Generate quests with this distribution:
1. MAIN quest (directly related to ${profile['fitnessGoal']})
2. SECONDARY quest (somewhat related to primary goal)
3. SIDE quest (different stat focus for balance)

Examples based on goal:

Brain Activity Enhancement:
- Study new subject for 30 minutes
- Solve 10 math problems or logic puzzles
- Memorize 20 new vocabulary words
- Read educational material for 45 minutes
- Practice a new skill for 20 minutes

Strength Enhancement:
- Complete 50 push-ups (can be broken into sets)
- Hold plank position for 2 minutes total
- Do 30 bodyweight squats
- Carry groceries/books for 10 minutes
- Climb stairs 5 times

Format as JSON array (NO markdown, ONLY JSON):
[
  {
    "id": "quest_12345",
    "title": "Quest Title (use Solo Leveling terminology)",
    "description": "Detailed description of what hunter must accomplish",
    "difficulty": "E",
    "objectives": ["specific task 1", "specific task 2"],
    "rewards": {"xp": 50, "strength": 1, "agility": 0, "endurance": 1, "vitality": 0, "intelligence": 0},
    "category": "main"
  }
]
''';
  }

  // Complete corrected parsing method with proper syntax
 List<QuestModel> _parseQuestsFromAIResponse(String response) {
  try {
    // Clean the response - remove any markdown formatting
    String cleanedResponse = response.trim();
    
    // Remove markdown code blocks if present
   if (cleanedResponse.startsWith('```')) {
  cleanedResponse = cleanedResponse.replaceAll('```json', '').replaceAll('```', '');

   }
    
    cleanedResponse = cleanedResponse.trim();

    final jsonStart = cleanedResponse.indexOf('[');
    final jsonEnd = cleanedResponse.lastIndexOf(']') + 1;

    if (jsonStart != -1 && jsonEnd != 0) {
      final jsonString = cleanedResponse.substring(jsonStart, jsonEnd);
      final List<dynamic> questsJson = jsonDecode(jsonString);

      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: 24));

      return questsJson.map((json) => QuestModel(
        id: json['id'] ?? 'quest_${Random().nextInt(100000)}',
        title: json['title'] ?? 'Hunter Training',
        description: json['description'] ?? 'Complete hunter training objectives',
        questType: 'ongoing',
        difficulty: json['difficulty'] ?? 'E',
        objectives: List<String>.from(json['objectives'] ?? ['Complete training']),
        rewards: _parseRewards(json['rewards']),
        category: json['category'] ?? 'main',
        createdAt: now,
        expiresAt: expiresAt,
      )).toList();
    }
  } catch (e) {
    print('Error parsing AI response: $e');
    print('Response was: $response');
  }

  return [];
}


  // Safe rewards parsing method
  Map<String, int> _parseRewards(dynamic rewards) {
    if (rewards == null) {
      return {'xp': 50, 'intelligence': 1};
    }

    Map<String, int> parsedRewards = {};
    try {
      if (rewards is Map) {
        rewards.forEach((key, value) {
          String stringKey = key.toString();
          int intValue;

          // Handle both String and int values
          if (value is String) {
            intValue = int.tryParse(value) ?? 0;
          } else if (value is int) {
            intValue = value;
          } else if (value is double) {
            intValue = value.round();
          } else {
            intValue = 0;
          }

          parsedRewards[stringKey] = intValue;
        });

        // Ensure we always have at least XP
        if (!parsedRewards.containsKey('xp')) {
          parsedRewards['xp'] = 50;
        }

        return parsedRewards;
      }
    } catch (e) {
      print('Error parsing rewards: $e');
    }

    // Fallback to default rewards
    return {'xp': 50, 'intelligence': 1};
  }

  // Enhanced methods for different quest types
  Future<List<QuestModel>> generateSpecificQuests({
    required int count,
    required String urgency,
  }) async {
    final userProfile = await _getUserProfileFromPrefs();
    final prompt = _buildUrgentQuestPrompt(userProfile, count, urgency);
    final response = await _model.generateContent([Content.text(prompt)]);
    return _parseQuestsFromAIResponse(response.text ?? '');
  }

  Future<List<QuestModel>> generateUpcomingQuests({
    required int currentLevel,
    required int count,
  }) async {
    final userProfile = await _getUserProfileFromPrefs();
    final prompt = _buildUpcomingQuestPrompt(userProfile, currentLevel, count);
    final response = await _model.generateContent([Content.text(prompt)]);
    final quests = _parseQuestsFromAIResponse(response.text ?? '');

    return quests.map((quest) => QuestModel(
      id: quest.id,
      title: quest.title,
      description: quest.description,
      questType: 'upcoming',
      difficulty: quest.difficulty,
      objectives: quest.objectives,
      rewards: quest.rewards,
      category: quest.category,
      createdAt: quest.createdAt,
      expiresAt: quest.expiresAt,
      unlockLevel: currentLevel + Random().nextInt(5) + 2,
    )).toList();
  }

  String _buildUrgentQuestPrompt(Map<String, dynamic> profile, int count, String urgency) {
    return '''
URGENT: Generate $count immediate quests for hunter level ${profile['currentLevel']} focused on ${profile['fitnessGoal']}.
These quests are needed NOW because the hunter just completed their previous tasks.

Hunter Profile:
- Class: ${profile['hunterClass']}
- Goal: ${profile['fitnessGoal']}
- Stats: STR:${profile['strength']}, AGI:${profile['agility']}, END:${profile['endurance']}

Make them achievable within the next few hours and appropriate for their current stats.

Return ONLY JSON array format:
[{"id": "quest_123", "title": "Title", "description": "Description", "difficulty": "E", "objectives": ["task"], "rewards": {"xp": 50}, "category": "main"}]
''';
  }

  String _buildUpcomingQuestPrompt(Map<String, dynamic> profile, int currentLevel, int count) {
    return '''
Generate $count challenging upcoming quests for a ${profile['hunterClass']} hunter.
These should be unlocked at levels ${currentLevel + 2} to ${currentLevel + 6}.

Hunter Profile:
- Current Level: $currentLevel
- Class: ${profile['hunterClass']}
- Goal: ${profile['fitnessGoal']}

Focus on ${profile['fitnessGoal']} but make them more difficult than current quests.
These represent growth milestones.

Return ONLY JSON array format:
[{"id": "quest_123", "title": "Advanced Title", "description": "Challenging Description", "difficulty": "D", "objectives": ["harder task"], "rewards": {"xp": 100}, "category": "main"}]
''';
  }

  Future<void> _generateDefaultQuests() async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: 24));

    final defaultQuests = [
      QuestModel(
        id: 'default_${now.millisecondsSinceEpoch}_1',
        title: '🏃‍♂️ Hunter\'s Morning Routine',
        description: 'Complete basic physical training to maintain hunter readiness',
        questType: 'ongoing',
        difficulty: 'E',
        objectives: ['Complete 20 push-ups', 'Walk for 15 minutes'],
        rewards: {'xp': 50, 'strength': 1, 'endurance': 1},
        category: 'main',
        createdAt: now,
        expiresAt: expiresAt,
      ),
      QuestModel(
        id: 'default_${now.millisecondsSinceEpoch}_2',
        title: '🧠 Mental Sharpening',
        description: 'Keep your mind sharp for strategic thinking',
        questType: 'ongoing',
        difficulty: 'E',
        objectives: ['Read for 20 minutes', 'Review daily goals'],
        rewards: {'xp': 40, 'intelligence': 2},
        category: 'secondary',
        createdAt: now,
        expiresAt: expiresAt,
      ),
      QuestModel(
        id: 'default_${now.millisecondsSinceEpoch}_3',
        title: '💧 Hydration Protocol',
        description: 'Maintain optimal hunter vitality',
        questType: 'ongoing',
        difficulty: 'E',
        objectives: ['Drink 8 glasses of water', 'Take vitamins if available'],
        rewards: {'xp': 30, 'vitality': 2},
        category: 'side',
        createdAt: now,
        expiresAt: expiresAt,
      ),
    ];

    for (final quest in defaultQuests) {
      await QuestDatabaseHive.addQuest(quest);
    }
  }
}
