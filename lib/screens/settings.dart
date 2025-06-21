import 'package:flutter/material.dart';
import 'package:fitcourse/screens/account_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcourse/models/exercise_models.dart';
import 'package:fitcourse/screens/login.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF111214),
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 38, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(color: Colors.orange.shade800, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Personal Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(color: Colors.orange.shade800, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Log Out',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text(
                'exercise details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user?.uid)
                    .collection('exercises')
                    .orderBy('start_time', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No exercises recorded yet.'),
                    );
                  }

                  final exercises = snapshot.data!.docs.map((doc) {
                    return Exercise.fromMap(doc.data() as Map<String, dynamic>);
                  }).toList();

                  return ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final startTime = exercise.statuses.isNotEmpty
                          ? DateFormat('yyyy-MM-dd HH:mm').format(exercise.statuses.first.time)
                          : 'N/A';
                      final endTime = exercise.statuses.isNotEmpty
                          ? DateFormat('yyyy-MM-dd HH:mm').format(exercise.statuses.last.time)
                          : 'N/A';

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 32.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900, 
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: 60.0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade800,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      DateFormat('dd').format(exercise.statuses.first.time),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start: $startTime',
                                          style: const TextStyle(fontSize: 16, fontFamily: 'PlusJakartaSans', color: Colors.white, fontWeight: FontWeight.w600), 
                                        ),
                                        Text(
                                          'End: $endTime',
                                          style: const TextStyle(fontSize: 16, fontFamily: 'PlusJakartaSans', color: Colors.white, fontWeight: FontWeight.w600), 
                                        ),
                                        Text(
                                          'Duration: ${exercise.duration} seconds',
                                          style: const TextStyle(fontSize: 16, fontFamily: 'PlusJakartaSans', color: Colors.white, fontWeight: FontWeight.w600), 
                                        ),
                                        Text(
                                          'Distance: ${exercise.distance.toStringAsFixed(2)} meters',
                                          style: const TextStyle(fontSize: 16, fontFamily: 'PlusJakartaSans', color: Colors.white, fontWeight: FontWeight.w600), 
                                        ),
                                        Text(
                                          'Avg Speed: ${exercise.avgSpeed.toStringAsFixed(2)} m/s',
                                          style: const TextStyle(fontSize: 16, fontFamily: 'PlusJakartaSans', color: Colors.white, fontWeight: FontWeight.w600), 
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
