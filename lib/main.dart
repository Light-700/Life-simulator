import 'package:flutter/material.dart';
import 'dart:math';
// ignore: unused_import
import 'package:provider/provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

import 'src/screens/achievements.dart';
import 'src/screens/profile.dart';
import 'src/screens/stats.dart';
import 'src/screens/tasks.dart';

Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = await determineLoginStatus();
  final username = prefs.getString('username') ?? '';
  
  runApp(
    ChangeNotifierProvider(//makes the ProfileNotifier available to the entire app
      create: (context) {
        final notifier = ProfileNotifier();
        if (isLoggedIn && username.isNotEmpty) {
          notifier.updateName(username);
        }
        return notifier;
      },
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}


Future<bool> determineLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});
  

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Simulator',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'ArsenalSC' ,
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: isLoggedIn ? MyHomePage() : LoginScreen(),// is the user logged in?
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
                    return 'Password must be at least 5 characters long';
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
          MaterialPageRoute(builder: (context) => MyHomePage())
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
  String uname = "Fragment of Light"; // Default value
  
  ProfileNotifier() {
    // constructor execution function to load the username
    _loadUsername();
  }
  
  String get username => uname;
  
  // Load username from SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString(usernameKey); 
    
    if (savedUsername != null) {
      uname = savedUsername;
      notifyListeners();
    }
  }
  
  Future<void> updateName(String newuname) async {
    uname = newuname;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(usernameKey, newuname);
    
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('password');
    uname = "Fragment of Light";
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
                value: 0.7,
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


