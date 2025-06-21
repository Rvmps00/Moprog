import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:fitcourse/utils/my_colors.dart';
import 'package:fitcourse/utils/page_route_builder.dart';
import 'package:fitcourse/screens/navigator.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isSaving = false;
  final TextStyle _textStyle = const TextStyle(color: Colors.white, fontSize: 16.0);
  final TextStyle _option = const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w200);
  String? _selectedGender;
  String? _selectedFitnessLevel;
  Map<String, bool> _fitnessGoals = {
    'Weight Control': false,
    'Muscle Gain': false,
    'Improves Stamina': false,
    'Flexibility': false,
    'Medical Reason': false,
    'General Fitness': false,
  };
  DateTime? _selectedDateOfBirth;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        final data = userData.data();
        if (data != null) {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _selectedGender = data['gender'];
          if (data['dateOfBirth'] != null) {
            _selectedDateOfBirth = (data['dateOfBirth'] as Timestamp).toDate();
          }
          _heightController.text = data['height']?.toString() ?? '';
          _weightController.text = data['weight']?.toString() ?? '';
          _selectedFitnessLevel = data['fitnessLevel'];
          if (data['fitnessGoals'] != null) {
            (_fitnessGoals.keys.toList()).forEach((goal) {
              _fitnessGoals[goal] = data['fitnessGoals'][goal] ?? false;
            });
          }
          setState(() {});
        }
      }
    }
  }

  Future<void> _saveUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'gender': _selectedGender,
        'dateOfBirth': _selectedDateOfBirth,
        'height': double.tryParse(_heightController.text),
        'weight': double.tryParse(_weightController.text),
        'fitnessLevel': _selectedFitnessLevel,
        'fitnessGoals': _fitnessGoals,
      }, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _saveAndNavigateToApp() async {
    setState(() {
      _isSaving = true;
    });
    
    await _saveUserData();
    
    if (!mounted) return;
    
    // Navigate to main app after successful save
    Navigator.pushReplacement(
      context,
      pageRouteBuilder(
        (context) => const NavigatorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Center(
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 18.0, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: _option,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0), 
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 18.0, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: _option,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gender:',
                            style: TextStyle(color: Colors.white, fontSize: 16.0),
                          ),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'Male',
                                groupValue: _selectedGender,
                                visualDensity: const VisualDensity(
                                  horizontal: VisualDensity.minimumDensity,
                                  vertical: VisualDensity.minimumDensity,
                                ),
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                                activeColor: Colors.white,
                              ),
                              Text(
                                'Male',
                                style: _option,
                              ),
                              const SizedBox(width: 16.0),
                              Radio<String>(
                                value: 'Female',
                                visualDensity: const VisualDensity(
                                  horizontal: VisualDensity.minimumDensity,
                                  vertical: VisualDensity.minimumDensity,
                                ),
                                groupValue: _selectedGender,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                                activeColor: Colors.white,
                              ),
                              Text(
                                'Female',
                                style: _option,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDateOfBirth ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null && pickedDate != _selectedDateOfBirth) {
                            setState(() {
                              _selectedDateOfBirth = pickedDate;
                            });
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date of Birth:',
                              style: TextStyle(color: Colors.white, fontSize: 16.0),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDateOfBirth == null
                                      ? 'Select Date'
                                      : '${_selectedDateOfBirth!.toLocal()}'.split(' ')[0],
                                  style: _option,
                                ),
                                const Icon(Icons.calendar_today, color: Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: TextFormField(
                      controller: _heightController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        labelStyle: _option,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        contentPadding: EdgeInsets.all(16.0), 
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0), 
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: TextFormField(
                      controller: _weightController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: _option,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        contentPadding: EdgeInsets.all(16.0), 
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Fitness Information',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedFitnessLevel,
                decoration: const InputDecoration(
                  labelText: 'Current Fitness Level',
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.0),
                ),
                
                style: const TextStyle(color: Colors.white),
                items: ['Beginner', 'Intermediate', 'Advanced', 'Pro'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedFitnessLevel = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Fitness Goal', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white)),
            
            ..._fitnessGoals.keys.map((String key) {
              return SizedBox(
                height: 40.0, 
                child: CheckboxListTile(
                  title: Text(key, style: _option),
                  value: _fitnessGoals[key],
                  onChanged: (bool? value) {
                    setState(() {
                      _fitnessGoals[key] = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero, 
                  visualDensity: VisualDensity.compact, 
                ),
              );
            }).toList(),
            const SizedBox(height: 24.0),
            // Add Save and Skip buttons
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _isSaving ? null : _saveAndNavigateToApp,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Skip button
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  pageRouteBuilder(
                    (context) => const NavigatorScreen(),
                  ),
                );
              },
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        )
      ),
    );
  }
}
