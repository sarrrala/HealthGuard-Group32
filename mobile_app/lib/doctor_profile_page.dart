import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: const Color(0xFF167D8D),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(
        child: Text('Please sign in first.'),
      )
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load doctor profile.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!.data();

          final name =
          (data?['name'] ?? 'Doctor').toString();

          final email =
          (data?['email'] ?? user.email ?? '').toString();

          final specialization =
          (data?['specialization'] ?? 'Not specified')
              .toString();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.account_circle,
                size: 100,
                color: Color(0xFF167D8D),
              ),

              const SizedBox(height: 16),

              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(email),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Specialization'),
                  subtitle: Text(specialization),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) return;

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }
}