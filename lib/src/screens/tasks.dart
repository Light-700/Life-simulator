// lib/src/screens/tasks.dart - CORRECTED VERSION with BuildContext safety
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/quest_database_hive.dart';
import '../../services/dynamic_quest_manager.dart';
import '../../models/quest_model.dart';
import '../../services/daily_quest_manager.dart';

class TaskPage extends StatefulWidget {
  final void Function(int) navigator;

  const TaskPage({
    super.key,
    required this.navigator,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Quest data management
  List<QuestModel> ongoingQuests = [];
  List<QuestModel> completedQuests = [];
  List<QuestModel> upcomingQuests = [];
  bool isLoading = true;
   bool questSystemReady = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuests();
    _initializeAndLoadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

   Future<void> _initializeAndLoadQuests() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      // Wait for quest system to be ready (with timeout)
      await Future.any([
        _waitForQuestSystem(),
        Future.delayed(Duration(seconds: 5)), // 5 second timeout
      ]);
      
      questSystemReady = true;
      await _loadQuests();
    } catch (e) {
      print('Error initializing quest page: $e');
      questSystemReady = false;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

   Future<void> _waitForQuestSystem() async {
    while (!DailyQuestManager.instance.isInitialized || 
           !DynamicQuestManager.instance.isInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
  
  // Load quests from database
  Future<void> _loadQuests() async {
    if (!mounted) return; // SAFETY CHECK
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLevel = prefs.getInt('level') ?? 1;
      
      // Load quest data from Hive database
      ongoingQuests = QuestDatabaseHive.getActiveQuests();
      completedQuests = QuestDatabaseHive.getQuestsByType('completed').take(20).toList();
      upcomingQuests = QuestDatabaseHive.getUpcomingQuests(currentLevel);
      
      // Add daily quests to ongoing if they exist
      final dailyQuests = QuestDatabaseHive.getTodaysDailyQuests();
      ongoingQuests.addAll(dailyQuests.where((q) => !q.isCompleted));
      
      print('🎯 Loaded: ${ongoingQuests.length} ongoing, ${completedQuests.length} completed, ${upcomingQuests.length} upcoming');
      
    } catch (e) {
      print('❌ Error loading quests: $e');
    } finally {
      if (mounted) { // SAFETY CHECK
        setState(() => isLoading = false);
      }
    }
  }
  
  // Complete a quest - CORRECTED with mounted checks
  Future<void> _completeQuest(QuestModel quest) async {
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = prefs.getInt('level') ?? 1;
    
    try {
      await QuestDatabaseHive.completeQuest(quest.id, currentLevel);
      await DynamicQuestManager.instance.onQuestCompleted(quest.id);
      
      // FIXED: Check if widget is still mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Quest Completed: ${quest.title}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Reload quests
      await _loadQuests();
      
    } catch (e) {
      print('❌ Error completing quest: $e');
      
      // FIXED: Check if widget is still mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error completing quest'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Force generate new quests - CORRECTED with mounted checks
  Future<void> _generateNewQuests() async {
    if (!mounted) return; // SAFETY CHECK
    setState(() => isLoading = true);
    
    try {
      await DynamicQuestManager.instance.forceGenerateQuests();
      await _loadQuests();
      
      // FIXED: Check if widget is still mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 New quests generated!'),
            backgroundColor: Color.fromARGB(255, 238, 33, 18),
          ),
        );
      }
    } catch (e) {
      print('❌ Error generating quests: $e');
    } finally {
      if (mounted) { // SAFETY CHECK
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

if (isLoading && !questSystemReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color.fromARGB(255, 238, 33, 18),
            ),
            SizedBox(height: 16),
            Text(
              'Initializing Player System...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Existing Home Button - Preserved
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => widget.navigator(0),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 238, 33, 18),
                side: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              ),
              child: Text(
                'Home',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // New Quest Generation Button
            IconButton(
              onPressed: _generateNewQuests,
              icon: Icon(
                Icons.refresh,
                color: Color.fromARGB(255, 238, 33, 18),
              ),
              tooltip: 'Generate New Quests',
            ),
          ],
        ),
        
        // Quest Log Title
        Center(
          child: Text(
            "Quest Log",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 238, 33, 18),
              fontSize: 18,
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Tab Bar Section
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: Color.fromARGB(255, 238, 33, 18), width: 2),
              bottom: BorderSide(color: Color.fromARGB(255, 238, 33, 18), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Color.fromARGB(255, 238, 33, 18),
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Color.fromARGB(255, 238, 33, 18),
            indicatorWeight: 3.0,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.access_time, size: 20),
                text: 'Ongoing (${ongoingQuests.length})',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline, size: 20),
                text: 'Completed (${completedQuests.length})',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.schedule, size: 20),
                text: 'Upcoming (${upcomingQuests.length})',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
            ],
          ),
        ),
        
        // Tab Content Area
        Expanded(
          child: isLoading 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color.fromARGB(255, 238, 33, 18),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading Quest Data...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    child: _buildOngoingContent(),
                  ),
                  SingleChildScrollView(
                    child: _buildCompletedContent(),
                  ),
                  SingleChildScrollView(
                    child: _buildUpcomingContent(),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  // Build ongoing quests with real data
  Widget _buildOngoingContent() {
    if (ongoingQuests.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Color.fromARGB(255, 238, 33, 18),
            ),
            SizedBox(height: 16),
            Text(
              'No Active Quests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The System is generating new quests for you.\nCheck back in a few minutes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateNewQuests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 238, 33, 18),
              ),
              child: Text('Generate Quests Now'),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ...ongoingQuests.map((quest) => _buildQuestCard(quest, true)),
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // Build completed quests with real data
  Widget _buildCompletedContent() {
    if (completedQuests.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.military_tech,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'No Completed Quests Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete your ongoing quests to see them here.\nYour achievements will be recorded for all time!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Recent Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          ...completedQuests.map((quest) => _buildQuestCard(quest, false)),
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // Build upcoming quests with real data
  Widget _buildUpcomingContent() {
    if (upcomingQuests.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.lock_clock,
              size: 64,
              color: Colors.amber,
            ),
            SizedBox(height: 16),
            Text(
              'No Upcoming Quests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The System will unlock new challenges\nas you grow stronger and level up!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Future Challenges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          ...upcomingQuests.map((quest) => _buildQuestCard(quest, false)),
          SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // Build individual quest card
  Widget _buildQuestCard(QuestModel quest, bool canComplete) {
    Color getDifficultyColor(String difficulty) {
      switch (difficulty) {
        case 'E': return Colors.grey;
        case 'D': return Colors.green;
        case 'C': return Colors.blue;
        case 'B': return Colors.purple;
        case 'A': return Colors.orange;
        case 'S': return Color.fromARGB(255, 238, 33, 18);
        default: return Colors.grey;
      }
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: getDifficultyColor(quest.difficulty),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha:0.8),
              Colors.grey[900]!.withValues(alpha:0.9),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quest Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      quest.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // Difficulty Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getDifficultyColor(quest.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${quest.difficulty}-Rank',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Time Remaining
                      if (quest.questType == 'ongoing' || quest.questType == 'daily')
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha:0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quest.formattedTimeRemaining,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Quest Description
              Text(
                quest.description,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
              
              SizedBox(height: 12),
              
              // Quest Objectives
              ...quest.objectives.map((objective) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: Color.fromARGB(255, 238, 33, 18),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        objective,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              
              SizedBox(height: 12),
              
              // Rewards Section
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha:0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Rewards:',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: quest.rewards.entries.map((reward) => 
                        Text(
                          '+${reward.value} ${reward.key.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.green[300],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
              
              // Complete Button for ongoing quests
              if (canComplete && !quest.isCompleted) ...[
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeQuest(quest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 238, 33, 18),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Complete Quest'),
                  ),
                ),
              ],
              
              // Completion Status
              if (quest.isCompleted) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Completed ${_formatDate(quest.completedAt)}',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Unlock Level for upcoming quests
              if (quest.questType == 'upcoming') ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.amber,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Unlocks at Level ${quest.unlockLevel}',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
