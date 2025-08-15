import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:isolate';

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
  static const String completedTasksKey = 'completedTasks';

  String uname = "Fragment of Light";
  int _baseExp = 1;
  int baselevel = 1;
  int _totalExp = 100;
  String hunterClass = "E-class";
  int _completedTasks = 0;
  int _previousLevel = 1;
  
  // Optimized batch processing
  List<Map<String, dynamic>> _pendingXPRewards = [];
  Timer? _xpProcessingTimer;
  bool _isProcessingXP = false;
  
  // Performance optimization: Cache frequently accessed data
  Map<String, int>? _cachedStats;
  DateTime? _lastStatsCacheTime;
  static const Duration _statsCacheDuration = Duration(minutes: 5);
  
  // Background computation isolate
  Isolate? _computationIsolate;
  ReceivePort? _isolateReceivePort;

  ProfileNotifier() {
    _loadUserData();
    _initializeBackgroundComputation();
  }

  String get username => uname;
  int get xp => _baseExp;
  int get level => baselevel;
  int get totalExp => _totalExp;
  String get className => hunterClass;
  int get completedTasks => _completedTasks;

  // Initialize background computation isolate for heavy operations
  Future<void> _initializeBackgroundComputation() async {
    _isolateReceivePort = ReceivePort();
    _computationIsolate = await Isolate.spawn(
      _backgroundComputationEntryPoint,
      _isolateReceivePort!.sendPort,
    );
  }

  // Background isolate entry point
  static void _backgroundComputationEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        switch (message['type']) {
          case 'calculateStats':
            final result = await _performStatCalculation(
              message['totalPoints'],
              message['fromLevel'],
              message['toLevel'],
            );
            sendPort.send({'type': 'statsResult', 'result': result});
        }
      }
    });
  }

  // Heavy stat calculation in background isolate
  static Future<Map<String, int>> _performStatCalculation(
    int totalPoints,
    int fromLevel,
    int toLevel,
  ) async {
    final relevantTasks = TaskDatabase.getTasksBetweenLevels(fromLevel, toLevel);
    
    if (relevantTasks.isEmpty) {
      return {
        'strength': (totalPoints * 0.2).round(),
        'agility': (totalPoints * 0.2).round(),
        'endurance': (totalPoints * 0.2).round(),
        'vitality': (totalPoints * 0.2).round(),
        'intelligence': (totalPoints * 0.2).round(),
      };
    }

    final taskTypeCounts = <String, int>{
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

    return _distributePointsByTaskShare(
      taskTypeCounts: taskTypeCounts,
      totalPoints: totalPoints,
    );
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Batch load all data at once for better performance
    final futures = <Future<dynamic>>[
  Future.value(prefs.getString(usernameKey)),
  Future.value(prefs.getInt(expKey)),
  Future.value(prefs.getInt(levelKey)),
  Future.value(prefs.getInt(totExpKey)),
  Future.value(prefs.getString(hunterClassKey)),
  Future.value(prefs.getInt(completedTasksKey)),
  Future.value(prefs.getInt('totalStats')),
];

    final results = await Future.wait(futures);
    
    if (results[0] != null) uname = results[0] as String;
    if (results[1] != null) _baseExp = results[1] as int;
    if (results[5] != null) _completedTasks = results[5] as int;
    if (results[4] != null) hunterClass = results[4] as String;
    if (results[2] != null) {
      baselevel = results[2] as int;
      _totalExp = getXPRequiredForLevel(baselevel);
      hunterClass = _calculateHunterRank(results[6] as int?);
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
    
    // Use background isolate for task creation to avoid main thread blocking
    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskName: taskName ?? 'Unknown Task',
      taskType: taskType ?? 'General',
      xpReward: exp,
      completedAtLevel: baselevel,
      completedAt: DateTime.now(),
    );
    
    // Store task in background to avoid blocking UI
    unawaited(TaskDatabase.addCompletedTask(task));
    
    _pendingXPRewards.add({
      'exp': exp,
      'taskName': taskName ?? 'Unknown Task',
      'taskType': taskType ?? 'General',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _completedTasks++;
    
    // Batch SharedPreferences updates
    unawaited(_batchUpdatePreferences());
    
    _scheduleBatchProcessing();
  }

  // Optimized batch preferences update
  Future<void> _batchUpdatePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(completedTasksKey, _completedTasks);
  }

  void _scheduleBatchProcessing() {
    _xpProcessingTimer?.cancel();
    _xpProcessingTimer = Timer(const Duration(milliseconds: 300), () {
      _processBatchedXP();
    });
  }

  Future<void> _processBatchedXP() async {
    if (_isProcessingXP || _pendingXPRewards.isEmpty) return;
    _isProcessingXP = true;

    try {
      int totalXP = 0;
      final completedTasks = <String>[];
      final taskTypeXP = <String, int>{};

      for (final reward in _pendingXPRewards) {
        totalXP += reward['exp'] as int;
        completedTasks.add(reward['taskName'] as String);
        final taskType = reward['taskType'] as String;
        taskTypeXP[taskType] = (taskTypeXP[taskType] ?? 0) + (reward['exp'] as int);
      }

      // Show notification usin unawaited
      unawaited(NotificationService().showBatchCompletionNotification(
        completedTasks, 
        totalXP, 
        taskTypeXP
      ));

      await _processHunterProgression(_baseExp + totalXP);

      _pendingXPRewards.clear();
    } finally {
      _isProcessingXP = false;
      notifyListeners();
    }
  }

  // Optimized progression processing with background computation
  Future<void> _processHunterProgression(int totalCurrentXP) async {
    final prefs = await SharedPreferences.getInstance();
    int currentLevel = baselevel;
    int remainingXP = totalCurrentXP;
    final levelUps = <int>[];
    final oldRank = hunterClass;
    final levelUpStartLevel = _previousLevel;

    while (remainingXP >= getXPRequiredForLevel(currentLevel)) {
      remainingXP -= getXPRequiredForLevel(currentLevel);
      currentLevel++;
      levelUps.add(currentLevel);
      
      // Yield control to prevent blocking of main thread
      if (levelUps.length % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    if (levelUps.isNotEmpty) {
      baselevel = currentLevel;
      _totalExp = getXPRequiredForLevel(currentLevel);
      final statPoint = levelUps.length * 5;

      // Using cached stats if available and recent
      Map<String, int> statBonuses;
      if (_shouldUseCachedStats()) {
        statBonuses = _cachedStats!;
      } else {
        // Calculate stats in background isolate
        statBonuses = await _calculateStatBonusesInBackground(
          statPoint,
          levelUpStartLevel,
          currentLevel
        );
        _cacheStats(statBonuses);
      }

      final newTotalStats = await _applyStatBonuses(statBonuses);
      hunterClass = _calculateHunterRank(newTotalStats);

      final notificationFutures = <Future>[];
      
      notificationFutures.add(
        NotificationService().showStatPointAllocation(statBonuses, statPoint)
      );

      if (levelUps.length > 1) {
        notificationFutures.add(
          NotificationService().showMassivePowerSpike(
            levelUps.first - 1, 
            currentLevel, 
            levelUps.length
          )
        );
      } else {
        notificationFutures.add(
          NotificationService().showSingleLevelUp(levelUps.first - 1, levelUps.first)
        );
      }

      if (hunterClass != oldRank) {
        notificationFutures.add(
          NotificationService().showRankAdvancement(oldRank, hunterClass)
        );
      }

      // Execute all notifications in parallel
      unawaited(Future.wait(notificationFutures));

      // Batch save all progression data
      await _batchSaveProgressionData(prefs, currentLevel, newTotalStats);
    }

    _baseExp = remainingXP;
    await prefs.setInt(expKey, _baseExp);
    notifyListeners();
  }

  Future<int> _applyStatBonuses(Map<String, int> bonuses) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Batch read current stats usin the future class
    final currentStats = <String, int>{};
    final futures = <Future<int?>>[];
    final statKeys = ['strengthStat', 'agilityStat', 'enduranceStat', 'vitalityStat', 'intelligenceStat'];
    
    for (final key in statKeys) {
      futures.add(Future.value(prefs.getInt(key)));
    }
    
    final results = await Future.wait(futures);
    for (int i = 0; i < statKeys.length; i++) {
      currentStats[statKeys[i]] = results[i] ?? 0;
    }

    final newStats = <String, int>{
      'strengthStat': currentStats['strengthStat']! + (bonuses['strength'] ?? 0),
      'agilityStat': currentStats['agilityStat']! + (bonuses['agility'] ?? 0),
      'enduranceStat': currentStats['enduranceStat']! + (bonuses['endurance'] ?? 0),
      'vitalityStat': currentStats['vitalityStat']! + (bonuses['vitality'] ?? 0),
      'intelligenceStat': currentStats['intelligenceStat']! + (bonuses['intelligence'] ?? 0),
    };

    final writeFutures = <Future<bool>>[];
    for (final entry in newStats.entries) {
      writeFutures.add(prefs.setInt(entry.key, entry.value));
    }
    
    await Future.wait(writeFutures);

    final newTotalStats = newStats.values.reduce((a, b) => a + b);
    await prefs.setInt('totalStats', newTotalStats);

    return newTotalStats;
  }

  // Cache management for frequently accessed stats
  bool _shouldUseCachedStats() {
    return _cachedStats != null && 
           _lastStatsCacheTime != null && 
           DateTime.now().difference(_lastStatsCacheTime!).compareTo(_statsCacheDuration) < 0;
  }

  void _cacheStats(Map<String, int> stats) {
    _cachedStats = Map<String, int>.from(stats);
    _lastStatsCacheTime = DateTime.now();
  }

  Future<void> _batchSaveProgressionData(
    SharedPreferences prefs, 
    int currentLevel, 
    int newTotalStats
  ) async {
    final futures = <Future<bool>>[
      prefs.setInt(levelKey, currentLevel),
      prefs.setInt(totExpKey, _totalExp),
      prefs.setInt('totalStats', newTotalStats),
      prefs.setString(hunterClassKey, hunterClass),
    ];

    await Future.wait(futures);
  }

  Future<Map<String, int>> _calculateStatBonusesInBackground(
    int totalPoints,
    int fromLevel,
    int toLevel,
  ) async {
    final completer = Completer<Map<String, int>>();
    try {
      if (_isolateReceivePort != null) {
        final subscription = _isolateReceivePort!.listen((message) {
          if (message is Map<String, dynamic> && message['type'] == 'statsResult') {
            completer.complete(message['result'] as Map<String, int>);
          }
        });

        _isolateReceivePort!.sendPort.send({
          'type': 'calculateStats',
          'totalPoints': totalPoints,
          'fromLevel': fromLevel,
          'toLevel': toLevel,
        });

        final result = await completer.future;
        await subscription.cancel();
        return result;
      }
      
      // fall back to calculating in the main isolate
      return _calculateStatBonusesFromTasks(totalPoints, fromLevel, toLevel);
    } catch(e) {
      return _calculateStatBonusesFromTasks(totalPoints, fromLevel, toLevel);
    }
  }

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

static Map<String, int> _distributePointsByTaskShare({
    required Map<String, int> taskTypeCounts,
    required int totalPoints,
  }) {
    final positive = taskTypeCounts.entries.where((e) => e.value > 0).toList();
    final result = <String, int>{
      for (final k in taskTypeCounts.keys) k.toLowerCase(): 0,
    };

    if (positive.isEmpty) return result;

    final totalCount = positive.fold<int>(0, (sum, e) => sum + e.value);
    int allocated = 0;
    final remainders = <MapEntry<String, double>>[];

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

    int remaining = totalPoints - allocated;
    if (remaining > 0) {
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

 Map<String, int> _calculateStatBonusesFromTasks(int totalPoints, int fromLevel, int toLevel) {
    // Using the optimized cached calculation instead of expensive queries
    return TaskDatabase.calculateStatsWithCache(totalPoints, fromLevel, toLevel);
  }


  int getXPRequiredForLevel(int level) {
    if (level == 1) return 100;
    double growthRate = _getHunterGrowthRate(level);
    int baseExp = 100;
    return (baseExp * pow(growthRate, level - 1)).round();
  }

  double _getHunterGrowthRate(int level) {
    if (level >= 150) return 1.15;
    if (level >= 90) return 1.12;
    if (level >= 75) return 1.10;
    if (level >= 50) return 1.08;
    if (level >= 25) return 1.07;
    return 1.06;
  }

  String _calculateHunterRank(int? totalStats) {
    int totalPossible = 600;
    if (totalStats == null) return "E-class";
    if (totalStats > totalPossible) return "God Mode";
    if (totalStats > (0.9 * totalPossible)) return "S-class";
    if (totalStats > (0.75 * totalPossible)) return "A-class";
    if (totalStats > (0.65 * totalPossible)) return "B-class";
    if (totalStats > (0.55 * totalPossible)) return "C-class";
    if (totalStats > (0.4 * totalPossible)) return "D-class";
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

 Future<Map<String, int>> getTaskTypeStats() async {
    return {
      'Strength': TaskDatabase.getTaskTypeCountFast('strength'),
      'Agility': TaskDatabase.getTaskTypeCountFast('agility'),
      'Endurance': TaskDatabase.getTaskTypeCountFast('endurance'),
      'Vitality': TaskDatabase.getTaskTypeCountFast('vitality'),
      'Intelligence': TaskDatabase.getTaskTypeCountFast('intelligence'),
    };
  }

  void optimizeMemory() {
    TaskDatabase.optimizeMemory();
  }

  Map<String, dynamic> getMemoryStats() {
    return TaskDatabase.getMemoryUsage();
  }

  @override
  void dispose() {
    _xpProcessingTimer?.cancel();
    _computationIsolate?.kill(priority: Isolate.immediate);
    _isolateReceivePort?.close();
    super.dispose();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _xpProcessingTimer?.cancel();
    _computationIsolate?.kill(priority: Isolate.immediate);
    _isolateReceivePort?.close();
    
    await prefs.clear();
    uname = "Fragment of Light";
    _baseExp = 0;
    baselevel = 1;
    _totalExp = 100;
    hunterClass = "E-Rank Hunter";
    _completedTasks = 0;
    _pendingXPRewards.clear();
    _isProcessingXP = false;
    _cachedStats = null;
    _lastStatsCacheTime = null;
    
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


