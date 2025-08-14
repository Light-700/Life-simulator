import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

import 'src/screens/achievements.dart';
import 'src/screens/profile.dart';
import 'src/screens/stats.dart';
import 'src/screens/tasks.dart';
import 'src/screens/extended_login.dart';
import 'services/task_database.dart';
import 'models/task_model.dart';
import 'services/notification_service.dart';

Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await TaskDatabase.initialize();

  await NotificationService().initialize();
  
  // Check if user is logged in and profile is completed
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = await determineLoginStatus();
  final bool profileCompleted = prefs.getBool('profileCompleted') ?? false;
  final username = prefs.getString('username') ?? '';
  
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final notifier = ProfileNotifier();
        if (isLoggedIn && username.isNotEmpty) {
          notifier.updateName(username);
        }
        return notifier;
      },
      child: MyApp(
        isLoggedIn: isLoggedIn, 
        profileCompleted: profileCompleted
      ),
    ),
  );
}



Future<bool> determineLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool profileCompleted;
  
  const MyApp({
    super.key, 
    required this.isLoggedIn,
    this.profileCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget home;
    
    if (!isLoggedIn) {
      home = LoginScreen();
    } else if (!profileCompleted) {
      home = ExtendedDetailsPage();
    } else {
      home = MyHomePage();
    }
    
    return MaterialApp(
      title: 'Life Simulator',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'ArsenalSC',
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color.fromARGB(255, 228, 190, 21),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username',labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              prefixIcon: Icon(Icons.person, color: Color.fromARGB(255, 238, 33, 18)),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 238, 33, 18),),),),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  if (value.length < 5) {
                    return 'Username must be at least 5 characters long';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                    labelStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 238, 33, 18)),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 238, 33, 18),
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email',labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              prefixIcon: Icon(Icons.email, color: Color.fromARGB(255, 238, 33, 18)),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                   return 'Please enter a valid email';
                 }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async{
                  if (_formKey.currentState!.validate()) {
                    // Get the ProfileNotifier instance and update username
                    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
                    profileNotifier.updateName(_usernameController.text);

                    final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', _usernameController.text);
                    await prefs.setString('email', _emailController.text);
                    await prefs.setString('password', _passwordController.text);
                   if (context.mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => ExtendedDetailsPage())
        );
      } 
                  }
                },
                style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 238, 33, 18),
                foregroundColor: Colors.white,
              ),
                child: const Text('Sign in'),
              ),
            ],
          ),),
      ),
    );
  }
}

class ProfileNotifier extends ChangeNotifier {
  static const String usernameKey = 'username';
  static const String expKey = 'exp';
  static const String levelKey = 'level';
  static const String totExpKey = 'totExp';
  static const String hunterClassKey = 'Class';
  static const String completedTasksKey = 'completedTasks'; //i may remove if its unnecessary
  
  String uname = "Fragment of Light"; // Default value
  int _baseExp = 1;
  int baselevel = 1;
  int _totalExp = 100; // Base total experience for level 1
  String hunterClass = "E-class";
  int _completedTasks = 0;  //i may remove if its unnecessary
  int _previousLevel = 1;

  List<Map<String, dynamic>> _pendingXPRewards = [];
  Timer? _xpProcessingTimer;
  bool _isProcessingXP = false;
  
  ProfileNotifier() {
    //constructor to load user data
    _loadUserData();
  }
  
  String get username => uname;
  int get xp => _baseExp;
  int get level => baselevel;
  int get totalExp => _totalExp;
  String get className => hunterClass;
  int get completedTasks => _completedTasks; //i may remove if its unnecessary
  
  // Load all user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString(usernameKey);
    final savedExp = prefs.getInt(expKey);
    final savedLevel = prefs.getInt(levelKey);
    final savedTotExp = prefs.getInt(totExpKey);
    final savedClass = prefs.getString(hunterClassKey);
    final savedCompletedTasks = prefs.getInt(completedTasksKey);  //i may remove if its unnecessary
    final totalStats = prefs.getInt('totalStats'); // total stats for class determination
    
     if (savedUsername != null) uname = savedUsername;
    if (savedExp != null) _baseExp = savedExp;
    if (savedCompletedTasks != null) _completedTasks = savedCompletedTasks;
    if (savedClass != null) hunterClass = savedClass;
    
    if (savedLevel != null) {
      baselevel = savedLevel;
      _totalExp = getXPRequiredForLevel(baselevel); 
      hunterClass = _calculateHunterRank(totalStats);/* need to change it because hunter class
                                                   is not set by level but by stats*/
    }
    
    notifyListeners();
  }
  
  Future<void> updateName(String newuname) async {
    uname = newuname;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(usernameKey, newuname);
    
    notifyListeners();
  }
  
  Future<void> updateXP(int exp, {String? taskName, String? taskType}) async {
    _previousLevel = baselevel;

     final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskName: taskName ?? 'Unknown Task',
      taskType: taskType ?? 'General',
      xpReward: exp,
      completedAtLevel: baselevel, // Current level when task was completed
      completedAt: DateTime.now(),
    );

    await TaskDatabase.addCompletedTask(task);

    _pendingXPRewards.add({
      'exp': exp,
      'taskName': taskName ?? 'Unknown Task',
      'taskType': taskType ?? 'General',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Update task counter
    _completedTasks++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(completedTasksKey, _completedTasks);
    
    // Schedule batch processing
    _scheduleBatchProcessing();
  }
  
    
  void _scheduleBatchProcessing() {
    _xpProcessingTimer?.cancel();
    
    // Allowing 500ms for multiple tasks to accumulate
    _xpProcessingTimer = Timer(Duration(milliseconds: 500), () {
      _processBatchedXP();
    });
  }
  
  Future<void> _processBatchedXP() async {
    if (_isProcessingXP || _pendingXPRewards.isEmpty) return;
    
    _isProcessingXP = true;
    final notify= NotificationService();

    // Calculate total XP and prepare notifications
    int totalXP = 0;
    List<String> completedTasks = [];
    Map<String, int> taskTypeXP = {};
    
    for (var reward in _pendingXPRewards) {
      totalXP += reward['exp'] as int;
      completedTasks.add(reward['taskName'] as String);
      
      String taskType = reward['taskType'] as String;
      taskTypeXP[taskType] = (taskTypeXP[taskType] ?? 0) + (reward['exp'] as int);
    }
    
    // Show batch completion notification
    await notify.showBatchCompletionNotification(completedTasks, totalXP, taskTypeXP); //batch completion notification
    
    // Process XP with multi-level support
    await _processHunterProgression(_baseExp + totalXP);
    
    // Clear processed rewards
    _pendingXPRewards.clear();
    _isProcessingXP = false;
    
    notifyListeners();
  }

 Future<void> _processHunterProgression(int totalCurrentXP) async {
    final prefs = await SharedPreferences.getInstance();
    final notify= NotificationService();
    await notify.initialize();

    int currentLevel = baselevel;
    int remainingXP = totalCurrentXP;
    List<int> levelUps = [];
    String oldRank = hunterClass;
   //int totalStats = prefs.getInt('totalStats') ?? 0; 
   int levelUpStartLevel = _previousLevel;

    // Handle multiple level-ups like Sung Jinwoo's power spikes
    while (remainingXP >= getXPRequiredForLevel(currentLevel)) {
      remainingXP -= getXPRequiredForLevel(currentLevel);
      currentLevel++;
      levelUps.add(currentLevel);
      
      // Brief delay for dramatic effect
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    // Update Hunter System data
    if (levelUps.isNotEmpty) {
      baselevel = currentLevel;
      _totalExp = getXPRequiredForLevel(currentLevel);
      int statPoint = levelUps.length * 5; // 5 stat points per level up
      Map<String, int> statBonuses = _calculateStatBonusesFromTasks(
        statPoint, 
        levelUpStartLevel, 
        currentLevel
      );

    int newTotalStats =await  _applyStatBonuses(statBonuses);
     hunterClass = _calculateHunterRank(newTotalStats);

      await NotificationService().showStatPointAllocation(statBonuses, statPoint);
    
/*
      int strength= 0;
      int agility = 0;  
      int intelligence = 0;
      int endurance = 0;
      int vitality = 0;
      strength+= statBonuses['strength'] ?? 0;
      agility+= statBonuses['agility'] ?? 0;
      intelligence+= statBonuses['intelligence'] ?? 0;
      endurance+= statBonuses['endurance'] ?? 0;
      vitality+= statBonuses['vitality'] ?? 0;
    await prefs.setInt('strengthStat', strength);
    await prefs.setInt('agilityStat', agility);
    await prefs.setInt('enduranceStat', endurance);
    await prefs.setInt('vitalityStat', vitality);
    await prefs.setInt('intelligenceStat', intelligence);
    totalStats += strength + agility + intelligence + endurance + vitality;
      */ 

    //initial anchor point for stat bonuses
       
      //progression notifications
      if (levelUps.length > 1) {
        await notify.showMassivePowerSpike(levelUps.first - 1, currentLevel, levelUps.length);//shows power spike notification
      } else {
        await notify.showSingleLevelUp(levelUps.first - 1, levelUps.first);//shows single level up notification
      }
      
      // class advancement*/
      if (hunterClass != oldRank) {
       await notify.showRankAdvancement(oldRank, hunterClass);//shows rank advancement notification 
        await prefs.setString(hunterClassKey, hunterClass);
      }
      
      // need to check and implement these notifications
      
      // Save progression data
      await prefs.setInt(levelKey, currentLevel);
      await prefs.setInt(totExpKey, _totalExp);
      
      await prefs.setInt('totalStats', newTotalStats);
    }
    
    _baseExp = remainingXP;
    await prefs.setInt(expKey, _baseExp);
    notifyListeners();
  }

   Future<int> _applyStatBonuses(Map<String, int> bonuses) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update individual stats
    int currentStrength = prefs.getInt('strengthStat') ?? 0;
    int currentAgility = prefs.getInt('agilityStat') ?? 0;
    int currentEndurance = prefs.getInt('enduranceStat') ?? 0;
    int currentVitality = prefs.getInt('vitalityStat') ?? 0;
    int currentIntelligence = prefs.getInt('intelligenceStat') ?? 0;
    
    await prefs.setInt('strengthStat', currentStrength + (bonuses['strength'] ?? 0));
    await prefs.setInt('agilityStat', currentAgility + (bonuses['agility'] ?? 0));
    await prefs.setInt('enduranceStat', currentEndurance + (bonuses['endurance'] ?? 0));
    await prefs.setInt('vitalityStat', currentVitality + (bonuses['vitality'] ?? 0));
    await prefs.setInt('intelligenceStat', currentIntelligence + (bonuses['intelligence'] ?? 0));
    
    // Update total stats
    int newTotalStats = (currentStrength + (bonuses['strength'] ?? 0)) +
                       (currentAgility + (bonuses['agility'] ?? 0)) +
                       (currentEndurance + (bonuses['endurance'] ?? 0)) +
                       (currentVitality + (bonuses['vitality'] ?? 0)) +
                       (currentIntelligence + (bonuses['intelligence'] ?? 0));
    
    await prefs.setInt('totalStats', newTotalStats);

    return newTotalStats;
  }


  Map<String, int> _calculateStatBonusesFromTasks(int totalPoints, int fromLevel, int toLevel) {
    // Get tasks completed between level range from Hive
    List<TaskModel> relevantTasks = TaskDatabase.getTasksBetweenLevels(fromLevel, toLevel);
    
    if (relevantTasks.isEmpty) {
      // Default distribution if no tasks found
      return {
        'strength': (totalPoints * 0.2).round(),
        'agility': (totalPoints * 0.2).round(),
        'endurance': (totalPoints * 0.2).round(),
        'vitality': (totalPoints * 0.2).round(),
        'intelligence': (totalPoints * 0.2).round(),
      };
    }
    
final Map<String, int> taskTypeCounts = {
  'Strength': 0,
  'Agility': 0,
  'Endurance': 0,
  'Vitality': 0,
  'Intelligence': 0,
};

for (final task in relevantTasks) {
  final normalized = _normalizeTaskType(task.taskType);
  if (taskTypeCounts.containsKey(normalized)) {
    taskTypeCounts[normalized] = taskTypeCounts[normalized]! + 1;
  }
}

final hasAny = taskTypeCounts.values.any((v) => v > 0);
if (!hasAny) {
  // Even split fallback (optional); otherwise return zeros as-is
  final per = (totalPoints / taskTypeCounts.length).floor();
  final Map<String, int> even = {
    for (final k in taskTypeCounts.keys) k.toLowerCase(): per
  };
  // Distribute remainder deterministically by key
  int rem = totalPoints - per * taskTypeCounts.length;
  final keys = taskTypeCounts.keys.map((k) => k.toLowerCase()).toList()..sort();
  for (int i = 0; i < rem; i++) {
    even[keys[i]] = even[keys[i]]! + 1;
  }
  return even;
}
final statBonuses = distributePointsByTaskShare(
  taskTypeCounts: taskTypeCounts,
  totalPoints: totalPoints,
);

return statBonuses;
  }

  /// Fair, exact distribution using the Largest Remainder (Hamilton) method.
/// - Respects proportions from taskTypeCounts
/// - Guarantees sum(result) == totalPoints
/// - Deterministic tie-breaking by stat key
/// I  took the elp of chatGPT for this
Map<String, int> distributePointsByTaskShare({
  required Map<String, int> taskTypeCounts, 
  required int totalPoints,
}) {
  // Normalize to positive-count entries for proportion; keep zeros in result
  final positive = taskTypeCounts.entries.where((e) => e.value > 0).toList();

  // Initialize result for all known stats (lowercased keys)
  final Map<String, int> result = {
    for (final k in taskTypeCounts.keys) k.toLowerCase(): 0,
  };

  // If no tasks found in the range, keep everything at 0 (caller can fallback)
  if (positive.isEmpty) {
    return result;
  }

  final int totalCount =
      positive.fold<int>(0, (sum, e) => sum + e.value);

  // First pass: base = floor(raw share), track remainder
  int allocated = 0;
  final List<MapEntry<String, double>> remainders = [];

  for (final e in positive) {
    final key = e.key.toLowerCase();
    final double share = e.value / totalCount;
    final double raw = totalPoints * share;
    final int base = raw.floor();
    final double remainder = raw - base;

    result[key] = base;
    allocated += base;
    remainders.add(MapEntry(key, remainder));
  }

  // Distribute the remaining points to the largest remainders
  int remaining = totalPoints - allocated;
  if (remaining > 0) {
    // Sort by remainder desc; tie-break by key asc to be deterministic
    remainders.sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    for (int i = 0; i < remaining; i++) {
      final k = remainders[i % remainders.length].key;
      result[k] = (result[k] ?? 0) + 1;
    }
  }

  return result;
}


    String _normalizeTaskType(String taskType) {
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
        return 'Intelligence'; // Default to intelligence for unknown types
    }
  }

  int getXPRequiredForLevel(int level) {
    if (level == 1) return 100;
    
    // Solo Leveling style: Different growth rates for different Hunter tiers
    double growthRate = _getHunterGrowthRate(level);
    int baseExp = 100;
    
    return (baseExp * pow(growthRate, level - 1)).round();
  }
  
  double _getHunterGrowthRate(int level) {
    if (level >= 150) return 1.15; // National Level Hunter (insane requirements)
    if (level >= 90) return 1.12;  // S-Rank Hunter (very hard)
    if (level >= 75) return 1.10;  // A-Rank Hunter (hard)
    if (level >= 50) return 1.08;  // B-Rank Hunter (moderate)
    if (level >= 25) return 1.07;  // C-Rank Hunter
    return 1.06; // D-E Rank Hunter (easier for beginners)
  }
  
  // SOLUTION 5: Hunter Rank System
  String _calculateHunterRank(int ?totalStats) {
//List<String> classes = ["E-class", "D-class", "C-class", "B-class", "A-class", "S-class",];
int totalPossible = 600; // Total possible stats for a Hunter
    if (totalStats == null) return "E-class"; // Default to E-class if no stats
    if (totalStats> totalPossible) return "God Mode";
    if (totalStats> (0.9*totalPossible)) return "S-class";
    if (totalStats> (0.75*totalPossible)) return "A-class";
    if (totalStats> (0.65*totalPossible)) return "B-class";
    if (totalStats> (0.55*totalPossible)) return "C-class ";
    if (totalStats> (0.4*totalPossible)) return "D-class";
    return "E-class"; 
  }

   double getXPProgress() {
    if (_totalExp == 0) return 0.0;
    return _baseExp / _totalExp;
  }
  
  int getXPNeededForNextLevel() {
    return _totalExp - _baseExp;
  }
  
  int getTotalXPEarned() {
    int totalXP = _baseExp;
    for (int i = 1; i < baselevel; i++) {
      totalXP += getXPRequiredForLevel(i);
    }
    return totalXP;
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cancel any pending processing
    _xpProcessingTimer?.cancel();
    
    // Clear all data
    await prefs.clear();
    
    // Reset to default values
    uname = "Fragment of Light";
    _baseExp = 0;
    baselevel = 1;
    _totalExp = 100;
    hunterClass = "E-Rank Hunter";
    _completedTasks = 0;
    _pendingXPRewards.clear();
    _isProcessingXP = false;
    
    notifyListeners();
  }

}


class MyHomePage extends StatefulWidget {
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
var index=0;
void navigator(int val){
  setState(() {
    index=val;
  });
}

  final GlobalKey _pageKey = GlobalKey();
  double _pageHeight = 0;

  @override
  void initState() {
    super.initState();
    // Measure the size after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeight();
    });
  }

  void _updateHeight() {
    final renderBox = _pageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _pageHeight = renderBox.size.height;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
Widget page =
   IndexedStack(
  index: index,
  children: [
    RealHome(navigator: navigator),
    ProfilePage(navigator: navigator),
    StatsPage(navigator: navigator),
    TaskPage(navigator: navigator),
    AchievementsPage(navigator: navigator),
  ],
);
    
   // Future.microtask(() => _switchPage(index));

    return PopScope(
      canPop: index==0,
      onPopInvokedWithResult: (didPop, result) {
  if (!didPop) {
    navigator(0); 
    print("back button called");
  }
},
      child: Scaffold(
        appBar: AppBar(backgroundColor: Color.fromARGB(255, 37, 29, 29),
          title:const Center(
            child: Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(text: ' Be Wise, ', style: TextStyle(fontStyle:  FontStyle.italic, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 238, 33, 18))),
                  TextSpan(text: 'and Game On!', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 18, 187, 238), )),
                ],
              ),
            ),
          ),
                ),
        body:AnimatedContainer(
                  duration: Duration(milliseconds: 300),
          width: MediaQuery.of(context).size.width + 1,
              height:MediaQuery.of(context).size.height+ 140/2 + 50, 
                 constraints: BoxConstraints(
         minHeight: _pageHeight,
                    ),
          child: page, 
              ),
        ),
    );

  }
}

class RealHome extends StatelessWidget {
  final void Function(int) navigator;

  const RealHome({
    super.key,
    required this.navigator,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                    (MediaQuery.of(context).padding.top + kToolbarHeight),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 70, bottom: 15, left: 10, right:10),
              child: LinearProgressIndicator(
                value: Provider.of<ProfileNotifier>(context).getXPProgress(),
                minHeight: 15,
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(255, 238, 33, 18),
                backgroundColor: const Color.fromARGB(131, 54, 14, 14),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: HexagonLayout(
                buttonLabels: const ['PROFILE', 'STATS', 'TASKS', 'ACHIEVEMENTS'],
                buttonActions: [
                  () => navigator(1),
                  () => navigator(2),
                  () => navigator(3),
                  () => navigator(4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class HexagonLayout extends StatelessWidget {
  final List<String> buttonLabels;
  final List<VoidCallback> buttonActions;

  const HexagonLayout({
    super.key,
    required this.buttonLabels,
    required this.buttonActions,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width+25;
    double screenHeight = MediaQuery.of(context).size.height;
    double radius = min(screenWidth, screenHeight) * 0.25;

    List<Widget> buttons = [];

    for (int i = 0; i < buttonLabels.length; i++) {
      double angle = pi / 2 * i;
      double x = radius * cos(angle);
      double y = radius * sin(angle);

      buttons.add(
        Positioned(
          left: screenWidth / 2 + x - 52,
          top: screenHeight / 4 + y - 25,
          child: Padding(
            padding: const EdgeInsets.only(top:25.0),
            child: OutlinedButton(
              onPressed: buttonActions[i],
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 238, 33, 18),
                side: const BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              ),
              child: Text(
                buttonLabels[i],
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: buttons,
    );
  }
}


