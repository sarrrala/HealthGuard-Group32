import 'package:flutter/material.dart';
import 'doctor_patients_page.dart';
import 'doctor_appointments_page.dart';
import 'doctor_profile_page.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthGuard | Doctor'),
        backgroundColor: const Color(0xFF167D8D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Welcome, Doctor!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Manage your patients and appointments.'),
          const SizedBox(height: 25),

          Card(
            child: ListTile(
              leading: const Icon(Icons.people, color: Colors.teal),
              title: const Text('My Patients'),
              subtitle: const Text('View patient health records'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorPatientsPage(),
                  ),
                );
              },            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: Colors.teal,
              ),
              title: const Text('Appointments'),
              subtitle: const Text('View upcoming appointments'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorAppointmentsPage(),
                  ),
                );
              },            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.monitor_heart,
                color: Colors.teal,
              ),
              title: const Text('Patient Health Data'),
              subtitle: const Text('View health measurements and history'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorPatientsPage(),
                  ),
                );
              },            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.person,
                color: Colors.teal,
              ),
              title: const Text('Doctor Profile'),
              subtitle: const Text('View your account information'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorProfilePage(),
                  ),
                );
              },            ),
          ),
        ],
      ),
    );
  }
}