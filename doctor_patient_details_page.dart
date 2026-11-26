import 'package:flutter/material.dart';

class DoctorPatientDetailsPage extends StatelessWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientDetailsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
        backgroundColor: const Color(0xFF167D8D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(
            Icons.account_circle,
            size: 80,
            color: Color(0xFF167D8D),
          ),

          const SizedBox(height: 12),

          Text(
            patientName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          const Card(
            child: ListTile(
              leading: Icon(Icons.monitor_heart),
              title: Text('Health Measurements'),
              subtitle: Text('Glucose, blood pressure, heart rate, weight'),
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('Health History'),
              subtitle: Text('Previous health readings'),
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(Icons.analytics),
              title: Text('AI Prediction Results'),
              subtitle: Text('View previous diabetes risk predictions'),
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text('Appointments'),
              subtitle: Text('Appointments with this patient'),
            ),
          ),
        ],
      ),
    );
  }
}