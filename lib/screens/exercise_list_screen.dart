import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcourse/models/exercise_models.dart';
import 'package:intl/intl.dart'; 

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to see your exercises.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exercises'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('exercises')
            .orderBy('start_time', descending: false) 
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

              return ListTile(
                title: Text('Exercise ${index + 1}'),
                subtitle: Text(
                    'Start: $startTime, End: $endTime\nDuration: ${exercise.duration} seconds, Distance: ${exercise.distance.toStringAsFixed(2)} meters, Avg Speed: ${exercise.avgSpeed.toStringAsFixed(2)} m/s'),
                
              );
            },
          );
        },
      ),
    );
  }
}
