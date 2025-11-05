import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
//import 'dart:isolate'; -> useless
import 'services/progression_analytics_hive.dart';
import '/models/daily_progress.dart';
import 'package:intl/intl.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart';

import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';

import 'src/screens/achievements.dart';
import 'src/screens/profile.dart';
import 'src/screens/stats.dart';
import 'src/screens/tasks.dart';
import 'src/screens/extended_login.dart';
import 'services/task_database.dart';
import 'models/task_model.dart';
import 'services/notification_service.dart';
import 'services/quest_database_hive.dart';
import 'services/dynamic_quest_manager.dart';
import 'services/daily_quest_manager.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart'; 

Future<void> main() async { 
  debugRepaintRainbowEnabled = true;
  WidgetsFlutterBinding.ensureInitialized();

  await TaskDatabase.initialize();
  await ProgressionAnalyticsHive.init(); 
  await QuestDatabaseHive.initialize();  
  await NotificationService().initialize();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ .env file not found, using fallback configuration');
  }

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = await determineLoginStatus();
  final bool profileCompleted = prefs.getBool('profileCompleted') ?? false;
  final username = prefs.getString('username') ?? '';
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final notifier = ProfileNotifier();
            if (isLoggedIn && username.isNotEmpty) {
              notifier.updateName(username);
            }
            return notifier;
          },
        ),
        ChangeNotifierProvider(create:(context) {
            final statNotifier = StatNotifier();
            if (isLoggedIn && profileCompleted) {
              statNotifier.initialize();
            }
            return statNotifier;
          },
          )
      ],
       child: MyApp(
            isLoggedIn: isLoggedIn, 
            profileCompleted: profileCompleted
          ),
    ),
  );
 _initializeQuestSystemInBackground();
}

void _initializeQuestSystemInBackground() {
  // Run after a delay to let the app fully render first
  Future.delayed(Duration(seconds: 2), () async {
    try {
      print('🎯 Starting background quest system initialization...');
      await DailyQuestManager.instance.initialize();
      await DynamicQuestManager.instance.initialize();
      print('✅ Quest system initialized successfully');
    } catch (e) {
      print('❌ Error initializing quest system: $e');
    }
  });
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
  final TextEditingController _confirmPasswordController = TextEditingController();// password confirmation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _loginUsernameController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _loginPasswordVisible = false;
  bool _isLoginMode = false; // bool for Toggling between login and sign-in

  Future<void> handleReLogin() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Checking if user data exists (returning user)
    final existingUsername = prefs.getString('username');
    final profileCompleted = prefs.getBool('profileCompleted') ?? false;
    
    if (existingUsername != null && profileCompleted) {
      await prefs.setBool('isLoggedIn', true);
      
      final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
      await profileNotifier._loadUserData(); 
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  MyHomePage()),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ExtendedDetailsPage()),
        );
      }
    }
  }

  Future<void> handleLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final existingUsername = prefs.getString('username');
    final existingPassword = prefs.getString('password');
    
    if (existingUsername == _loginUsernameController.text && 
        existingPassword == _loginPasswordController.text) {
      await handleReLogin();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password'),
            backgroundColor: Color.fromARGB(255, 238, 33, 18),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Player Login' : 'Player Registration'),
        backgroundColor: const Color.fromARGB(255, 228, 190, 21),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isLoginMode ? _buildLoginForm() : _buildSignInForm(),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Join the Association',
            style: TextStyle(
              color: Color.fromARGB(255, 238, 33, 18),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Player Name',
              labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              prefixIcon: Icon(Icons.person, color: Color.fromARGB(255, 238, 33, 18)),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              if (value.length < 5) {
                return 'Name must be at least 5 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_confirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              prefixIcon: const Icon(Icons.lock_outline, color: Color.fromARGB(255, 238, 33, 18)),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 238, 33, 18),
                ),
                onPressed: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
                profileNotifier.updateName(_usernameController.text);

                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', true);
                await prefs.setString('username', _usernameController.text);
                await prefs.setString('email', _emailController.text);
                await prefs.setString('password', _passwordController.text);

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ExtendedDetailsPage()),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 238, 33, 18),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            ),
            child: const Text(
              'Start Your Journey',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isLoginMode = true;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 238, 33, 18),
              side: const BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            ),
            child: const Text(
              'Old User?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Welcome Back, Player',
            style: TextStyle(
              color: Color.fromARGB(255, 238, 33, 18),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _loginUsernameController,
            decoration: const InputDecoration(
              labelText: 'Player Name',
              labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              prefixIcon: Icon(Icons.person, color: Color.fromARGB(255, 238, 33, 18)),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: !_loginPasswordVisible,
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
                  _loginPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 238, 33, 18),
                ),
                onPressed: () {
                  setState(() {
                    _loginPasswordVisible = !_loginPasswordVisible;
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              if (_loginFormKey.currentState!.validate()) {
                await handleLogin();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 238, 33, 18),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            ),
            child: const Text(
              'Enter the System',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isLoginMode = false;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 238, 33, 18),
              side: const BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            ),
            child: const Text(
              'New player?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileNotifier extends ChangeNotifier {

 static const String VERSION = "OPTIMIZED_V2"; 

  static const String usernameKey = 'username';
  static const String expKey = 'exp';
  static const String levelKey = 'level';
  static const String totExpKey = 'totExp';
  static const String hunterClassKey = 'Class';
  static const String completedTasksKey = 'completedTasks';
  static const String lifetimeXPKey = 'lifetimeXP';

  String uname = "Fragment of Light";
  int _baseExp = 1;
  int baselevel = 1;
  int _totalExp = 100;
  String hunterClass = "E-class";
  int _completedTasks = 0;
  int _previousLevel = 1;
  int _lifetimeXPEarned = 1;
  int _xpQueueId = 0;  // Unique ID for each batch
  bool _hasPendingBatch = false;  // Flag to prevent overlaps
  
  List<Map<String, dynamic>> _pendingXPRewards = [];
  Timer? _xpProcessingTimer;
  bool _isProcessingXP = false;
  
  Map<String, int>? _lastStatBonuses;

  ProfileNotifier() {
    print('🎯 ProfileNotifier VERSION: $VERSION'); 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  String get username => uname;
  int get xp => _baseExp;
  int get level => baselevel;
  int get totalExp => _totalExp;
  String get className => hunterClass;
  int get completedTasks => _completedTasks;
  bool get isProcessingXP => _isProcessingXP;

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      uname = prefs.getString(usernameKey) ?? "Fragment of Light";
      _baseExp = prefs.getInt(expKey) ?? 1;
      baselevel = prefs.getInt(levelKey) ?? 1;
      hunterClass = prefs.getString(hunterClassKey) ?? "E-class";
      _completedTasks = prefs.getInt(completedTasksKey) ?? 0;
      _lifetimeXPEarned = prefs.getInt(lifetimeXPKey) ?? 1;
      
      _totalExp = getXPRequiredForLevel(baselevel, hunterClass);
      
      final totalStats = prefs.getInt('totalStats');
      if (totalStats != null) {
        hunterClass = _calculateHunterRank(totalStats);
      }
      
      notifyListeners();
    } catch (e) {
      print("Error loading user data: $e");
      _resetToDefaults();
    }
  }

  void _resetToDefaults() {
    uname = "Fragment of Light";
    _baseExp = 1;
    baselevel = 1;
    _totalExp = 100;
    hunterClass = "E-class";
    _completedTasks = 0;
    _lifetimeXPEarned = 1;
  }

  Future<void> updateName(String newuname) async {
    uname = newuname;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(usernameKey, newuname);
    notifyListeners();
  }

 Future<void> updateXP(int exp, {String? taskName, String? taskType}) async {
  if (exp <= 0) return;
  
  print('📝 updateXP called: $exp XP (Task: $taskName, Type: $taskType)');
  
  _previousLevel = baselevel;
  
  final task = TaskModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    taskName: taskName ?? 'Unknown Task',
    taskType: taskType ?? 'General',
    xpReward: exp,
    completedAtLevel: baselevel,
    completedAt: DateTime.now(),
  );
  
  // Queue the reward
  _pendingXPRewards.add({
    'exp': exp,
    'taskName': taskName ?? 'Unknown Task',
    'taskType': taskType ?? 'General',
  });
  
  _completedTasks++;
  
  // Non-blocking save (fire and forget)
  unawaited(_saveCompletedTasksNonBlocking());
  unawaited(TaskDatabase.addCompletedTask(task));
  
  print('   Queue size: ${_pendingXPRewards.length}, Processing: $_isProcessingXP');
  
  if (!_isProcessingXP && !_hasPendingBatch) {
    _scheduleBatchProcessing();
  }
}

Future<void> _saveCompletedTasksNonBlocking() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(completedTasksKey, _completedTasks);
  } catch (e) {
    print('⚠️ Task count save failed: $e');
  }
}



 void _scheduleBatchProcessing() {
  _xpProcessingTimer?.cancel();

  final delay = _pendingXPRewards.length > 1
      ? const Duration(milliseconds: 100)
      : Duration.zero;

  _hasPendingBatch = true;
  print('⏰ Batch scheduled (delay: $delay, queue: ${_pendingXPRewards.length})');

  _xpProcessingTimer = Timer(delay, () {
    _hasPendingBatch = false;
    _processBatchedXP();
  });
}


Future<void> _processBatchedXP() async {
  print('\n🚀 Starting batch XP processing (Queue ID: $_xpQueueId)');
  print('   Queue size: ${_pendingXPRewards.length}');
  
  if (_isProcessingXP || _pendingXPRewards.isEmpty) {
    _hasPendingBatch = false;
    print('   Skipping: already processing or empty');
    return;
  }
  
  _isProcessingXP = true;
  final currentQueueId = ++_xpQueueId;
  
  try {
    // Calculate totals for entire batch
    int totalXP = 0;
    final allTasks = <String>[];
    final taskTypeXP = <String, int>{};
    
    for (final reward in _pendingXPRewards) {
      totalXP += reward['exp'] as int;
      allTasks.add(reward['taskName'] as String);
      final taskType = reward['taskType'] as String;
      taskTypeXP[taskType] = (taskTypeXP[taskType] ?? 0) + (reward['exp'] as int);
    }
    
    print('   Total batch XP: $totalXP from ${allTasks.length} tasks');
    
    if (totalXP == 0) return;
    
    _lifetimeXPEarned += totalXP;
    
    // Fire-and-forget analytics and notifications (non-blocking)
    unawaited(_handleBatchAnalyticsAndNotifications(totalXP, allTasks, taskTypeXP));
    
    // Core progression with timeout
    await _processHunterProgression(_baseExp + totalXP, _lifetimeXPEarned).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print('⚠️ Progression timed out - saving partial state');
        _baseExp += totalXP;  // Emergency save
        return Future.value();
      },
    );
    
    _pendingXPRewards.clear();
    print('   ✅ Batch processed (Queue ID: $currentQueueId)');
    
  } catch (e) {
    print('❌ Batch processing error (ID: $currentQueueId): $e');
    _pendingXPRewards.clear();  // Clear even on error to prevent loops
  } finally {
    _isProcessingXP = false;
    _hasPendingBatch = false;
    notifyListeners();
    
    // If more arrived during processing, schedule next
    if (_pendingXPRewards.isNotEmpty) {
      print('   🔄 More in queue - rescheduling');
      _scheduleBatchProcessing();
    }
  }
}

Future<void> _handleBatchAnalyticsAndNotifications(int totalXP, List<String> tasks, Map<String, int> taskTypeXP) async {
  try {
    ProgressionAnalyticsHive.recordExpGain(totalXP);
    

    NotificationService().showBatchCompletionNotification(tasks, totalXP, taskTypeXP);
    
  } catch (e) {
    print('⚠️ Analytics/Notification failed: $e');
  }
}



Future<void> _processHunterProgression(int totalCurrentXP, int lifetimeXPEarned) async {
  print('   🎮 Processing ${totalCurrentXP - _baseExp} XP...');
  
  final prefs = await SharedPreferences.getInstance();
  int currentLevel = baselevel;
  int remainingXP = totalCurrentXP;
  final levelUps = <int>[];
  final oldRank = hunterClass;
  
  // Efficient level-up loop (no delays)
  while (remainingXP >= getXPRequiredForLevel(currentLevel, hunterClass)) {
    final xpRequired = getXPRequiredForLevel(currentLevel, hunterClass);
    remainingXP -= xpRequired;
    currentLevel++;
    levelUps.add(currentLevel);
  }
  
  if (levelUps.isEmpty) {
    _baseExp = remainingXP;
    await prefs.setInt(expKey, _baseExp);
    notifyListeners();
    return;
  }
  
  // Update state
  baselevel = currentLevel;
  _totalExp = getXPRequiredForLevel(currentLevel, hunterClass);
  _baseExp = remainingXP;
  notifyListeners();
  
  // Bulk stat allocation (simple for now - no heavy DB calls)
  final statPoint = levelUps.length * 5;
  final statBonuses = _calculateStatBonuses(statPoint);  // Use your existing method
  
  final newTotalStats = await _applyStatBonuses(statBonuses);
  hunterClass = _calculateHunterRank(newTotalStats);
  
  // Non-blocking notifications (queue them)
  unawaited(_showLevelUpNotifications(levelUps, statBonuses, statPoint, oldRank));
  
  // Save in one batch
  await Future.wait([
    prefs.setInt(levelKey, baselevel),
    prefs.setInt(expKey, _baseExp),
    prefs.setInt(totExpKey, _totalExp),
    prefs.setString(hunterClassKey, hunterClass),
    prefs.setInt(lifetimeXPKey, lifetimeXPEarned),
    prefs.setInt('totalStats', newTotalStats),
  ]);
  
  print('   ✅ Progression complete: +${levelUps.length} levels');
}

Future<void> _showLevelUpNotifications(List<int> levelUps, Map<String, int> statBonuses, int statPoint, String oldRank) async {
  unawaited(NotificationService().showStatPointAllocation(statBonuses, statPoint));
  
  if (levelUps.length > 1) {
    unawaited(NotificationService().showMassivePowerSpike(levelUps.first - 1, levelUps.last, levelUps.length));
  } else {
    unawaited(NotificationService().showSingleLevelUp(levelUps.first - 1, levelUps.first));
  }
  
  if (hunterClass != oldRank) {
    baselevel = 1;
    _totalExp = getXPRequiredForLevel(1, hunterClass);
    _baseExp = 0;
    notifyListeners();
    unawaited(NotificationService().showRankAdvancement(oldRank, hunterClass));
  }
}

  Map<String, int> _calculateStatBonuses(int totalPoints) {
    if (_lastStatBonuses != null && 
        _lastStatBonuses!.values.reduce((a, b) => a + b) == totalPoints) {
      return _lastStatBonuses!;
    }
    
    final bonuses = TaskDatabase.calculateStatsWithCache(totalPoints, _previousLevel, baselevel);
    _lastStatBonuses = bonuses;
    return bonuses;
  }

Future<int> _applyStatBonuses(Map<String, int> bonuses) async {
  final prefs = await SharedPreferences.getInstance();
  
  final statKeys = ['strengthStat', 'agilityStat', 'enduranceStat', 'vitalityStat', 'intelligenceStat'];
  final bonusKeys = ['strength', 'agility', 'endurance', 'vitality', 'intelligence'];
  
  // Fix 1: Proper null-safe async reading
  final currentStats = <int>[];
  for (final key in statKeys) {
    final value = prefs.getInt(key) ?? 0;
    currentStats.add(value);
  }
  
  // Fix 2: Explicit int type
  final writeFutures = <Future<bool>>[];
  int totalStats = 0;
  
  for (int i = 0; i < statKeys.length; i++) {
    final int newValue = currentStats[i] + (bonuses[bonusKeys[i]] ?? 0);
    totalStats += newValue;
    writeFutures.add(prefs.setInt(statKeys[i], newValue));
  }
  
  writeFutures.add(prefs.setInt('totalStats', totalStats));
  await Future.wait(writeFutures);
  
  ProgressionAnalyticsHive.recordStatDelta(bonuses)
    .catchError((e) => print('Analytics error: $e'));

  return totalStats;
}

  /*void _showLevelUpNotifications(
    List<int> levelUps,
    Map<String, int> statBonuses,
    int statPoint,
    String oldRank,
  ) {
    NotificationService().showStatPointAllocation(statBonuses, statPoint)
      .catchError((e) => print('Notification error: $e'));
    
    if (levelUps.length > 1) {
      NotificationService().showMassivePowerSpike(
        levelUps.first - 1,
        levelUps.last,
        levelUps.length,
      ).catchError((e) => print('Notification error: $e'));
    } else {
      NotificationService().showSingleLevelUp(levelUps.first - 1, levelUps.first)
        .catchError((e) => print('Notification error: $e'));
    }
    
    if (hunterClass != oldRank) {
      NotificationService().showRankAdvancement(oldRank, hunterClass)
        .catchError((e) => print('Notification error: $e'));
    }
  }*/

  int getXPRequiredForLevel(int level, String rank) {
    if (level == 1) return 100;
    final growthRate = _getHunterGrowthRate(rank);
    return (100 * pow(growthRate, level - 1)).round();
  }

  double _getHunterGrowthRate(String rank) {
    switch (rank) {
      case 'S-rank': return 1.15;
      case 'A-rank': return 1.12;
      case 'B-rank': return 1.10;
      case 'C-rank': return 1.08;
      case 'D-rank': return 1.07;
      default: return 1.06;
    }
  }

  String _calculateHunterRank(int? totalStats) {
    if (totalStats == null) return "E-rank";
    const totalPossible = 600;
    
    if (totalStats > totalPossible) return "God Mode";
    if (totalStats > (0.9 * totalPossible)) return "S-rank";
    if (totalStats > (0.75 * totalPossible)) return "A-rank";
    if (totalStats > (0.65 * totalPossible)) return "B-rank";
    if (totalStats > (0.55 * totalPossible)) return "C-rank";
    if (totalStats > (0.4 * totalPossible)) return "D-rank";
    return "E-rank";
  }

  double getXPProgress() {
    if (_totalExp == 0) return 0.0;
    return (_baseExp / _totalExp).clamp(0.0, 1.0);
  }

  String getXPDisplay() => '$_baseExp/$_totalExp XP';

  int getXPNeededForNextLevel() => _totalExp - _baseExp;

  Future<int> getTotalXPEarned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(lifetimeXPKey) ?? _lifetimeXPEarned;
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

  void optimizeMemory() => TaskDatabase.optimizeMemory();

  Map<String, dynamic> getMemoryStats() => TaskDatabase.getMemoryUsage();

  @override
  void dispose() {
    _xpProcessingTimer?.cancel();
    super.dispose();
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    _xpProcessingTimer?.cancel();
    
    await prefs.clear();
    _resetToDefaults();
    _pendingXPRewards.clear();
    _isProcessingXP = false;
    _lastStatBonuses = null;
    
    notifyListeners();
  }

  Future<int> getCompletedQuestCount() async {
  try {
    return TaskDatabase.getAllTasks().length; // total completed quests
  } catch (_) {
    return 0;
  }
}

Future<int> getCompletedInPeriod({
  required DateTime from,
  required DateTime to,
}) async {
  final all = TaskDatabase.getAllTasks();
  return all.where((t) {
    final d = t.completedAt;
    return !d.isBefore(from) && !d.isAfter(to);
  }).length;
}

Future<int> getQuestsCompletedIn(Duration period) async {
  final now = DateTime.now();
  return getCompletedInPeriod(
    from: DateTime(now.year, now.month, now.day).subtract(period),
    to: now,
  );
}

Future<int> getCurrentDailyStreak({int windowDays = 30}) async {
  final now = DateTime.now();
  final startWindow = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: windowDays - 1));
  final all = TaskDatabase.getAllTasks()
      .where((t) => !t.completedAt.isBefore(startWindow))
      .toList();
  String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  final daysWithCompletions = all.map((t) {
    final d = t.completedAt;
    return dayKey(DateTime(d.year, d.month, d.day));
  }).toSet();

  int streak = 0;
  for (int i = 0; i < windowDays; i++) {
    final d = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: i));
    if (daysWithCompletions.contains(dayKey(d))) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _xpProcessingTimer?.cancel();
    
    await prefs.remove('isLoggedIn');
    _pendingXPRewards.clear();
    _isProcessingXP = false;
    _lastStatBonuses = null;
    
    notifyListeners();
  }
}

class StatNotifier extends ChangeNotifier {
  final Map<String, int> _baseStats = {};
  final Map<String, List<int>> _statHistory = {};
  bool _initialized = false;
  
  // Initialize with base stats from SharedPreferences and calculate history from Hive
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load base stats
    _baseStats['strength'] = prefs.getInt('strengthStat') ?? 10;
    _baseStats['agility'] = prefs.getInt('agilityStat') ?? 10;
    _baseStats['endurance'] = prefs.getInt('enduranceStat') ?? 10;
    _baseStats['vitality'] = prefs.getInt('vitalityStat') ?? 10;
    _baseStats['intelligence'] = prefs.getInt('intelligenceStat') ?? 10;
    
    await _calculateStatHistory();
    _initialized = true;
    notifyListeners();
  }

  /*StatNotifier() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }*/ 
  
  Future<void> _calculateStatHistory() async {
    final now = DateTime.now();
    final fromDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 89)); // Max range
    final toDate = DateTime(now.year, now.month, now.day);
    
    final progressData = await ProgressionAnalyticsHive.getRange(fromDate, toDate);
    final fmt = DateFormat('yyyy-MM-dd');
    
    // Initialize running totals for each stat
    final runningTotals = <String, int>{
      for (final stat in _baseStats.keys) stat: _baseStats[stat]!,
    };
    
    _statHistory.clear();
    for (final stat in _baseStats.keys) {
      _statHistory[stat] = [];
    }
    
    // Calculate cumulative values day by day
    for (int i = 0; i < 90; i++) {
      final d = fromDate.add(Duration(days: i));
      final key = fmt.format(d);
      final dp = progressData.firstWhere(
        (e) => e.dateKey == key,
        orElse: () => DailyProgress(dateKey: key),
      );
      
      for (final stat in _baseStats.keys) {
        final delta = dp.statDeltas[stat] ?? 0;
        runningTotals[stat] = runningTotals[stat]! + delta;
        _statHistory[stat]!.add(runningTotals[stat]!);
      }
    }
  }
  
  int getCurrentStatValue(String statName) {
    if (!_initialized) return _baseStats[statName] ?? 10;
    return _statHistory[statName]?.last ?? _baseStats[statName] ?? 10;
  }
  
  List<int> getStatHistoryForRange(String statName, int daysRange) {
    if (!_initialized || _statHistory[statName] == null) return [];
    final history = _statHistory[statName]!;
    final startIndex = history.length - daysRange;
    return history.sublist(startIndex.clamp(0, history.length));
  }
  
  // Call this when stats are updated
  Future<void> refreshStats() async {
    await initialize();
  }
}


class MyHomePage extends StatefulWidget {
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
var index=0;
void navigator(int val){
   if (val == 3 && !_questSystemReady) {
      _ensureQuestSystemInitialized();
    }
  setState(() {
    index=val;
  });
}

bool _questSystemReady = false;

  final GlobalKey _pageKey = GlobalKey();
  double _pageHeight = 0;

  @override
  void initState() {
    super.initState();
    // Measure the size after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeight();
      _ensureQuestSystemInitialized();
    });
  }

   Future<void> _ensureQuestSystemInitialized() async {
    if (_questSystemReady) return;
    
    try {
      // Check if quest managers are already initialized
      final dailyReady = DailyQuestManager.instance.isInitialized;
      final dynamicReady = DynamicQuestManager.instance.isInitialized;
      
      if (!dailyReady || !dynamicReady) {
        print('🔄 Quest system not ready, initializing now...');
        await Future.wait([
          if (!dailyReady) DailyQuestManager.instance.initialize(),
          if (!dynamicReady) DynamicQuestManager.instance.initialize(),
        ]);
      }
      
      setState(() => _questSystemReady = true);
      print('✅ Quest system ready for use');
    } catch (e) {
      print('⚠️ Quest system initialization deferred: $e');
    }
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
              child: RepaintBoundary(
                child: Consumer<ProfileNotifier>(
          builder: (context, profileNotifier, child) {
            return LinearProgressIndicator(
              value: profileNotifier.getXPProgress(),
              minHeight: 18,
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromARGB(255, 238, 33, 18),
              backgroundColor: const Color.fromARGB(131, 109, 29, 29),
            );
          },
        ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: HexagonLayout(
                buttonLabels: const ['pROFILE', 'sTATS', 'qUESTS', 'aCHIEVEMENTS'],
                buttonActions: [
                  () => navigator(1),
                  () => navigator(2),
                  () => navigator(3),
                  () => navigator(4),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [Text('Run app Notification Test =>', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                  FloatingActionButton.large(
                onPressed: () async {
                  //await NotificationService().showSingleLevelUp(0, 1);
                  // Checking if we should show the floating notification guide
                  await NotificationService().intelligentFloatingDetection(context);
                },
                heroTag: "Notification Setup",
                child: const Icon(Icons.notifications_active, color: Colors.white),
              ),
                ],
              ),
            )

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


