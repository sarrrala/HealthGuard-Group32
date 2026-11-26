import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAppointmentsPage extends StatelessWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Appointments'),
        backgroundColor: const Color(0xFF167D8D),
        foregroundColor: Colors.white,
      ),
      body: doctorId == null
          ? const Center(
        child: Text('Please sign in first.'),
      )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collectionGroup('appointments')
            .where('doctorUid', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load appointments.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final appointments = snapshot.data!.docs;

          if (appointments.isEmpty) {
            return const Center(
              child: Text('No appointments scheduled yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final data = appointment.data();

              final patientName = 'Patient';

              final timestamp = data['appointmentDateTime'] as Timestamp?;
              final appointmentDateTime = timestamp?.toDate();

              final date = appointmentDateTime == null
                  ? 'No date'
                  : '${appointmentDateTime.day}/${appointmentDateTime.month}/${appointmentDateTime.year}';

              final time = appointmentDateTime == null
                  ? 'No time'
                  : '${appointmentDateTime.hour.toString().padLeft(2, '0')}:${appointmentDateTime.minute.toString().padLeft(2, '0')}';

              final status =
              (data['status'] ?? 'pending').toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(
                      Icons.calendar_month,
                      color: Color(0xFF167D8D),
                    ),
                  ),
                  title: Text(patientName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('Date: $date'),
                      Text('Time: $time'),
                      Text('Status: $status'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}