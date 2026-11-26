import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_patient_details_page.dart';

class DoctorPatientsPage extends StatelessWidget {
  const DoctorPatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: const Color(0xFF167D8D),
        foregroundColor: Colors.white,
      ),
      body: doctorId == null
          ? const Center(child: Text('Please sign in first.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('doctorPatients')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load patients.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final patients = snapshot.data!.docs;

          if (patients.isEmpty) {
            return const Center(
              child: Text('No patients assigned yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final data = patients[index].data();

              final patientName =
              (data['patientName'] ?? 'Patient').toString();

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(patientName),
                  subtitle: const Text('Assigned patient'),
                  trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final patientId = (data['patientId'] ?? '').toString();

                      if (patientId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Patient ID is missing.'),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorPatientDetailsPage(
                            patientId: patientId,
                            patientName: patientName,
                          ),
                        ),
                      );
                    },
                ),
              );
            },
          );
        },
      ),
    );
  }
}