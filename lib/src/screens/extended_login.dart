import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math; 
import '../../main.dart';

class ExtendedDetailsPage extends StatefulWidget {
  const ExtendedDetailsPage({super.key});

  @override
  State<ExtendedDetailsPage> createState() => _ExtendedDetailsPageState();
}

class _ExtendedDetailsPageState extends State<ExtendedDetailsPage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _runningSpeedController = TextEditingController();
  final TextEditingController _lungCapacityController = TextEditingController();
  final TextEditingController _restingHeartRateController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _weightliftcapacity = TextEditingController();
  final TextEditingController _iqController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String _selectedJob = 'Student';
  String _selectedGoal = 'Brain Activity Enhancement';
  
  final List<String> _Jobs = [
    'Warrior',
    'Student',
    'Primary Sector',
    'Tertiary Sector',
    'Secondary Sector',
    'Administrator/Politician',
    'Homemaker',
    'Denizen of DarkWorld'
  ];
  
  final List<String> _fitnessGoals = [
    'Strength Enhancement',
    'Agility Training',
    'Endurance Building',
    'Combat Readiness',
    'Brain Activity Enhancement',
    'Overall Development'
  ];

String _class ='S-rank';

 Timer? _debounceTimer;
  
  void _handleTextChange() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Map<String, int> _calculateGameStats() {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double height = double.tryParse(_heightController.text) ?? 0;
    double speed = double.tryParse(_runningSpeedController.text) ?? 0;
    double lungCapacity = double.tryParse(_lungCapacityController.text) ?? 0;
    double heartRate = double.tryParse(_restingHeartRateController.text) ?? 0;
    double bodyFat = double.tryParse(_bodyFatController.text) ?? 0;
    double weightliftcapacity = double.tryParse(_weightliftcapacity.text) ?? 0;
    int iq = int.tryParse(_iqController.text) ?? 0;
    int age = int.tryParse(_ageController.text) ?? 0;
    
    double bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : 0;
    
    int strength = _calculateStrength(weight, height, bodyFat, bmi, weightliftcapacity);
    int agility = _calculateAgility(speed, bodyFat, bmi);
    int endurance = _calculateEndurance(lungCapacity, heartRate, age, bodyFat);
    int vitality = _calculateVitality(bmi, bodyFat, heartRate, age);
    int intelligence = _calculateIntelligence(iq, age);

    int totalStats =strength + agility + endurance + vitality + intelligence;
    int totalPossible = 600;

     if(totalStats>(0.9*totalPossible)){
      _class='S-rank';
     }
     else if(totalStats>(0.75*totalPossible)){
      _class = 'A-rank';
     }
     else if(totalStats>(0.65*totalPossible)){
      _class ='B-rank';
     }
     else if(totalStats>(0.55*totalPossible)){
      _class = 'C-rank';
     }
     else if(totalStats>(0.4*totalPossible)){
      _class = 'D-rank';
     }
     else{
      _class = 'E-rank';
     }
    
    return {
      'strength': strength,
      'agility': agility,
      'endurance': endurance,
      'vitality': vitality,
      'intelligence': intelligence,
      'totalStats': totalStats
    };
  }

  int _calculateStrength(double weight, double height, double bodyFat, double bmi, double weightliftcapacity) {
    double leanBodyMass = weight * (1 - (bodyFat / 100));
    double heightInM = height / 100;
    double ffmi = heightInM > 0 ? leanBodyMass / (heightInM * heightInM) : 0;
    
    int baseStrength = 0;
    if (ffmi >= 22) {
      baseStrength = 85;
    } else if (ffmi >= 20) {
      baseStrength = 70;
    } else if (ffmi >= 18) {
      baseStrength = 55;
    } else if (ffmi >= 16) {
      baseStrength = 40;
    } else {
      baseStrength = 25;
    }
    
    int heightBonus = (bmi >= 22 && bmi <= 27) ? 15 : 0;
    
    int physicalComponent = baseStrength + heightBonus;
    double normalizedPhysical = (physicalComponent / 100.0) * 100;
    
    weightliftcapacity = weightliftcapacity.clamp(0, 500);

    double normalizedWeightlift = (weightliftcapacity / 500.0) * 100;
    
    // 50% each component
    int finalStrength = ((normalizedPhysical * 0.5) + (normalizedWeightlift * 0.5)).toInt();
    
    return finalStrength.clamp(0, 200);
  }

  int _calculateAgility(double speed, double bodyFat, double bmi) {
    int speedScore = 0;
    if (speed >= 20) {
      speedScore = 40;
    } else if (speed >= 16) {
      speedScore = 30;
    } else if (speed >= 12) {
      speedScore = 20;
    } else {
      speedScore = 10;
    }
    
    int bodyFatScore = 0;
    if (bodyFat <= 10) {
      bodyFatScore = 35;
    } else if (bodyFat <= 15) {
      bodyFatScore = 25;
    } else if (bodyFat <= 20) {
      bodyFatScore = 15;
    } else {
      bodyFatScore = 5;
    }
    
    int bmiScore = 0;
    if (bmi >= 20 && bmi <= 24) {
      bmiScore = 25;
    } else if (bmi >= 18.5 && bmi <= 26) {
      bmiScore = 15;
    } else {
      bmiScore = 5;
    }
    
    return (speedScore + bodyFatScore + bmiScore).clamp(0, 100);
  }

  int _calculateEndurance(double lungCapacity, double heartRate, int age, double bodyFat) {
    // Lung capacity scoring (based on 6L average)
    int lungScore = 0;
    if (lungCapacity >= 6) {
      lungScore = 35;  
    } else if (lungCapacity >= 5) {
      lungScore = 25;  
    } else if (lungCapacity >= 4) {
      lungScore = 15; 
    } else {
      lungScore = 5;  
    }
    
    // Heart rate scoring (lower is better)
    int heartScore = 0;
    if (heartRate <= 60) {
      heartScore = 35; 
    } else if (heartRate <= 70) {
      heartScore = 25; 
    } else if (heartRate <= 80) {
      heartScore = 15;
    } else {
      heartScore = 5; 
    }
    
    int ageScore = 0;
    if (age <= 25) {
      ageScore = 20;
    } else if (age <= 35) {
      ageScore = 15;
    } else if (age <= 45) {
      ageScore = 10;
    } else {
      ageScore = 5;
    }
    
    // Body fat penalty (higher fat reduces endurance)
    int fatPenalty = bodyFat > 20 ? -10 : 0;
    return (lungScore + heartScore + ageScore + fatPenalty).clamp(0, 100);
  }

  int _calculateVitality(double bmi, double bodyFat, double heartRate, int age) {
    int bmiScore = 0;
    if (bmi >= 18.5 && bmi <= 24.9) {
      bmiScore = 30;
    } else if (bmi >= 17 && bmi <= 27) {
      bmiScore = 20;
    } else {
      bmiScore = 10;
    }
    
    int fatScore = 0;
    if (bodyFat >= 8 && bodyFat <= 15) {
      fatScore = 25;
    } else if (bodyFat >= 16 && bodyFat <= 20) {
      fatScore = 20;
    } else {
      fatScore = 10;
    }
    
    int cardioScore = 0;
    if (heartRate >= 60 && heartRate <= 80) {
      cardioScore = 25;
    } else if (heartRate >= 50 && heartRate <= 90) {
      cardioScore = 15;
    } else {
      cardioScore = 5;
    }
    
    int ageVitality = math.max(0, 100 - age); 
    int ageScore = (ageVitality * 0.2).round();
    
    return (bmiScore + fatScore + cardioScore + ageScore).clamp(0, 100);
  }

  int _calculateIntelligence(int iq, int age) {
    int iqbonus = 0;
    if (iq >= 130) {
      iqbonus = 30; 
    } else if (iq >= 110) {
      iqbonus = 20; 
    } else if (iq >= 90) {
      iqbonus = 10; 
    } else {
      iqbonus = 5; 
    }
    
    int ageBonus = 0;
    if (age <= 25) {
      ageBonus = 20;
    } else if (age <= 35) {
      ageBonus = 15;
    } else {
      ageBonus = 10;
    }
    
    int baseIntelligence = 50;
    return (baseIntelligence + iqbonus + ageBonus).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awakening Assessment'),
        backgroundColor: const Color.fromARGB(255, 228, 190, 21),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Hunter Association Registration\n Assessment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 238, 33, 18),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final age = int.tryParse(value);
                        if (age == null || age < 13 || age > 100) return 'Invalid age';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      icon: Icons.monitor_weight,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 20 || weight > 300) return 'Invalid weight';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _heightController,
                label: 'Height (cm)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final height = double.tryParse(value);
                  if (height == null || height < 100 || height > 250) return 'Invalid height';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildSectionHeader('Physical Performance Metrics'),
              const SizedBox(height: 10),
              
              _buildTextField(
                controller: _runningSpeedController,
                label: 'Max Running Speed (km/h)',
                icon: Icons.directions_run,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final speed = double.tryParse(value);
                  if (speed == null || speed < 0 || speed > 55) return 'Invalid speed';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              _buildTextField(
                controller: _lungCapacityController,
                label: 'Lung Capacity (liters)',
                icon: Icons.air,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final capacity = double.tryParse(value);
                  if (capacity == null || capacity < 1 || capacity > 8) return 'Invalid capacity';
                  return null;
                },
              ),
              const SizedBox(height: 15),
            
              _buildTextField(
                controller: _restingHeartRateController,
                label: 'Resting Heart Rate (bpm)',
                icon: Icons.favorite,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final hr = double.tryParse(value);
                  if (hr == null || hr < 40 || hr > 120) return 'Invalid HR';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _bodyFatController,
                label: 'Body Fat %',
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final bf = double.tryParse(value);
                  if (bf == null || bf < 3 || bf > 50) return 'Invalid %';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              _buildTextField(
                controller: _weightliftcapacity,
                label: 'Weight Lift Capacity (kg)',
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final wc = double.tryParse(value);
                  if (wc == null || wc < 0 || wc > 500) return 'Invalid capacity';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _iqController,
                label: 'IQ Level',
                icon: Icons.psychology,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final iq = int.tryParse(value);
                  if (iq == null || iq < 50 || iq > 200) return 'Invalid IQ';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildSectionHeader('Preferences'),
              const SizedBox(height: 10),
              
              _buildDropdown('User Job', _selectedJob, _Jobs, (value) {
                setState(() => _selectedJob = value!);
              }),
              const SizedBox(height: 16),
              
              _buildDropdown('Primary Goal', _selectedGoal, _fitnessGoals, (value) {
                setState(() => _selectedGoal = value!);
              }),
              const SizedBox(height: 30),
              
              if (_weightController.text.isNotEmpty && _heightController.text.isNotEmpty)
                _buildStatsPreview(),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _saveHunterData();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MyHomePage()),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 238, 33, 18),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Complete Awakening Registration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color.fromARGB(255, 238, 179, 18),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 238, 33, 18)),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 238, 33, 18)),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (value) => _handleTextChange(),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, 
      void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 238, 33, 18)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color.fromARGB(255, 37, 29, 29),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, 
                  color: Color.fromARGB(255, 238, 33, 18)),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPreview() {
    final stats = _calculateGameStats();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 238, 179, 18)),
        borderRadius: BorderRadius.circular(8),
        color: const Color.fromARGB(255, 37, 29, 29),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Predicted Hunter Stats',
            style: TextStyle(
              color: Color.fromARGB(255, 238, 179, 18),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 18, 187, 238),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _saveHunterData() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = _calculateGameStats();
    
    await prefs.setString('age', _ageController.text);
    await prefs.setString('weight', _weightController.text);
    await prefs.setString('height', _heightController.text);
    await prefs.setString('runningSpeed', _runningSpeedController.text);
    await prefs.setString('lungCapacity', _lungCapacityController.text);
    await prefs.setString('restingHeartRate', _restingHeartRateController.text);
    await prefs.setString('bodyFat', _bodyFatController.text);
    await prefs.setString('Job', _selectedJob);
    await prefs.setString('fitnessGoal', _selectedGoal);
    await prefs.setString('Class', _class); //calculated hunter class

    await prefs.setInt('strengthStat', stats['strength']!);
    await prefs.setInt('agilityStat', stats['agility']!);
    await prefs.setInt('enduranceStat', stats['endurance']!);
    await prefs.setInt('vitalityStat', stats['vitality']!);
    await prefs.setInt('intelligenceStat', stats['intelligence']!);
    await prefs.setInt('totalStats', stats['totalStats']!);// total stats based on which class is determined
    await prefs.setInt('exp', 1);
    await prefs.setInt('level', 1);
    await prefs.setInt('totExp', 100); // Base experience for level 1
    
    
    await prefs.setBool('profileCompleted', true);
  }
}
