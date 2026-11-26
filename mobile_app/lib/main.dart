import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'doctor_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(

    providerAndroid: AndroidDebugProvider(),  );
  runApp(const HealthGuardApp());
}

// ============================================================
// COLORS
// ============================================================

const background = Color(0xFFF3F7F1);
const green = Color(0xFF237A5A);
const darkGreen = Color(0xFF103B31);
const greyText = Color(0xFF718078);
const lightGreen = Color(0xFFDDEFE5);
const gold = Color(0xFFC99532);
const lightGold = Color(0xFFF8ECD5);
const red = Color(0xFFB85A45);
const lightRed = Color(0xFFF5E2DD);
const borderColor = Color(0xFFDCE5DF);

// ============================================================
// DATA MODELS
// ============================================================

class UserData {
  String name;
  String email;
  String age;
  String gender;
  String weight;
  String height;

  UserData({
    this.name = '',
    this.email = '',
    this.age = '',
    this.gender = '',
    this.weight = '63',
    this.height = '164',
  });

  String get firstName {
    if (name.trim().isEmpty) return 'User';
    return name.trim().split(' ').first;
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'HG';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class ActivityEntry {
  String name;
  String minutes;
  String calories;

  ActivityEntry({
    required this.name,
    required this.minutes,
    required this.calories,
  });
}

class MealEntry {
  String mealType;
  String food;
  String calories;

  MealEntry({
    required this.mealType,
    required this.food,
    required this.calories,
  });
}

class AppointmentEntry {
  String doctor;
  DateTime date;
  TimeOfDay time;

  AppointmentEntry({
    required this.doctor,
    required this.date,
    required this.time,
  });
}

class ChatMessage {
  String text;
  bool mine;

  ChatMessage({
    required this.text,
    required this.mine,
  });
}

final currentUser = UserData();

final List<ActivityEntry> activities = [
  ActivityEntry(
    name: 'Morning walk',
    minutes: '35',
    calories: '180',
  ),
  ActivityEntry(
    name: 'Yoga',
    minutes: '20',
    calories: '85',
  ),
];

final List<MealEntry> meals = [
  MealEntry(
    mealType: 'Breakfast',
    food: 'Oatmeal, banana, coffee',
    calories: '380',
  ),
  MealEntry(
    mealType: 'Lunch',
    food: 'Grilled chicken salad',
    calories: '520',
  ),
];

final List<AppointmentEntry> appointments = [];

// ============================================================
// APP
// ============================================================

class HealthGuardApp extends StatelessWidget {
  const HealthGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthGuard',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: green,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// COMMON UI
// ============================================================

InputDecoration fieldDecoration(
    String label,
    String hint,
    IconData icon,
    ) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: green),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: green,
        width: 2,
      ),
    ),
  );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AppButton(
      this.text,
      this.onPressed, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(
      this.text, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: greyText,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// PAGE SHELL — FIXED BACK BUTTON
// ============================================================

class PageShell extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const PageShell({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                8,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new,
                            color: green,
                            size: 18,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: green,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: trailing ?? const SizedBox(),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  Future<void> signIn() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password'),
        ),
      );
      return;
    }

    try {
      final UserCredential credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final String uid = credential.user!.uid;

      final DocumentSnapshot<Map<String, dynamic>> userDocument =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDocument.exists) {
        final data = userDocument.data()!;

        currentUser.name = (data['name'] ?? '').toString();
        currentUser.email = (data['email'] ?? '').toString();
        currentUser.age = (data['age'] ?? '').toString();
        currentUser.gender = (data['gender'] ?? '').toString();
      }

      if (!mounted) return;

      final String role =
      (userDocument.data()?['role'] ?? 'patient').toString();

      if (role == 'doctor') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const DoctorDashboardPage(),
          ),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const MainPage(),
          ),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Could not sign in.';

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 55,
          ),
          children: [
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: green,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'HealthGuard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkGreen,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Track the numbers that matter and\ncatch a change early.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: greyText,
                fontSize: 17,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 42),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: fieldDecoration(
                'Email',
                'you@example.com',
                Icons.email_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: fieldDecoration(
                'Password',
                'Enter your password',
                Icons.lock_outline,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            AppButton(
              'Sign in',
              signIn,
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 58,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const CreateAccountPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: green,
                  side: const BorderSide(color: green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Create an account',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password recovery will be connected to authentication later.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Forgot your password?',
                style: TextStyle(color: greyText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CREATE ACCOUNT
// ============================================================

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ageController = TextEditingController();

  String selectedGender = 'Female';

  Future<void> createAccount() async {
    // Check that all fields are filled correctly
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        ageController.text.trim().isEmpty ||
        passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete all fields. Password must be at least 8 characters.',
          ),
        ),
      );
      return;
    }

    try {
      // 1. Create the user in Firebase Authentication
      final UserCredential credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // 2. Get the unique Firebase user ID
      final String uid = credential.user!.uid;

      // 3. Save the user's profile in Cloud Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'age': ageController.text.trim(),
        'gender': selectedGender,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Keep the information in the app too
      currentUser.name = nameController.text.trim();
      currentUser.email = emailController.text.trim();
      currentUser.age = ageController.text.trim();
      currentUser.gender = selectedGender;

      if (!mounted) return;

      // 5. Open the main HealthGuard page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainPage(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Could not create account.';

      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Please choose a stronger password.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Create account',
      trailing: const Text(
        '1 of 2',
        textAlign: TextAlign.right,
        style: TextStyle(color: greyText),
      ),
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const LinearProgressIndicator(
            value: .5,
            minHeight: 8,
            color: green,
            backgroundColor: borderColor,
          ),

          const SizedBox(height: 22),

          const Text(
            'We start with the basics. You can add readings once you are in.',
            style: TextStyle(
              color: greyText,
              fontSize: 17,
              height: 1.5,
            ),
          ),

          const SectionTitle('About you'),

          TextField(
            controller: nameController,
            decoration: fieldDecoration(
              'Full name',
              'Enter your full name',
              Icons.person_outline,
            ),
          ),

          const SizedBox(height: 13),

          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: fieldDecoration(
              'Email',
              'you@example.com',
              Icons.email_outlined,
            ),
          ),

          const SizedBox(height: 13),

          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: fieldDecoration(
              'Password',
              'At least 8 characters',
              Icons.lock_outline,
            ),
          ),

          const SectionTitle('Health basics'),

          TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            decoration: fieldDecoration(
              'Age',
              'Enter your age',
              Icons.cake_outlined,
            ),
          ),

          const SizedBox(height: 13),

          DropdownButtonFormField<String>(
            initialValue: selectedGender,
            decoration: fieldDecoration(
              'Gender',
              'Select gender',
              Icons.people_outline,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Female',
                child: Text('Female'),
              ),
              DropdownMenuItem(
                value: 'Male',
                child: Text('Male'),
              ),
              DropdownMenuItem(
                value: 'Prefer not to say',
                child: Text('Prefer not to say'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedGender = value;
              });
            },
          ),

          const SizedBox(height: 25),

          AppButton(
            'Create account',
            createAccount,
          ),
        ],
      ),
    );
  }
}
// ============================================================
// MAIN PAGE
// ============================================================

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        refresh: () {
          setState(() {});
        },
      ),
      const HealthOverviewPage(),
      const InsightsPage(),
      ProfilePage(
        refresh: () {
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      backgroundColor: background,
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: lightGreen,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatelessWidget {
  final VoidCallback refresh;

  const HomePage({
    super.key,
    required this.refresh,
  });

  void openPage(
      BuildContext context,
      Widget page,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    ).then((_) => refresh());
  }

  Widget stat(
      String value,
      String label,
      ) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 5,
        ),
        child: Column(
          children: [
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: greyText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget feature(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Widget page, {
        Color iconBackground = lightGreen,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          openPage(
            context,
            page,
          );
        },
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: green,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: greyText,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning',
                  style: TextStyle(
                    color: Color(0xFFD4E9DF),
                    fontSize: 17,
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentUser.firstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    SizedBox(
                      width: 105,
                      height: 105,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CircularProgressIndicator(
                            value: .78,
                            strokeWidth: 10,
                            color: Color(0xFF9DE4B8),
                            backgroundColor:
                            Color(0xFF4D997C),
                          ),
                          Column(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: const [
                              Text(
                                '78',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              Text(
                                'out of 100',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 22),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Steady this week',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Updated recently',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              stat('98', 'Blood sugar'),
              const SizedBox(width: 9),
              stat('72', 'Heart rate'),
              const SizedBox(width: 9),
              stat('118/78', 'Pressure'),
            ],
          ),

          const SizedBox(height: 22),

          feature(
            context,
            Icons.monitor_heart_outlined,
            'Health data entry',
            'Log and review readings',
            const HealthDataPage(),
          ),

          feature(
            context,
            Icons.directions_walk,
            'Activity tracking',
            '${activities.length} activities logged',
            const ActivityPage(),
            iconBackground:
            const Color(0xFFE9E5F7),
          ),

          feature(
            context,
            Icons.restaurant_outlined,
            'Meals',
            '${meals.length} meals logged',
            const MealsPage(),
            iconBackground: lightGold,
          ),

          feature(
            context,
            Icons.smart_toy_outlined,
            'AI prediction',
            'View demo risk insights',
            const AIPredictionPage(),
          ),

          feature(
            context,
            Icons.notifications_none,
            'Alerts and feedback',
            'View reminders',
            const AlertsPage(),
            iconBackground: lightRed,
          ),

          feature(
            context,
            Icons.medical_services_outlined,
            'Care team',
            'Doctors, chat and appointments',
            const CareTeamPage(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HEALTH OVERVIEW
// ============================================================

class HealthOverviewPage extends StatelessWidget {
  const HealthOverviewPage({super.key});

  Widget option(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Widget page,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
        child: AppCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Health',
            style: TextStyle(
              color: darkGreen,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          option(
            context,
            Icons.monitor_heart_outlined,
            'Health data',
            'Blood sugar, pressure, heart rate and weight',
            const HealthDataPage(),
          ),

          option(
            context,
            Icons.directions_walk,
            'Activity',
            'Add and review your activities',
            const ActivityPage(),
          ),

          option(
            context,
            Icons.restaurant_outlined,
            'Meals',
            'Add and review your meals',
            const MealsPage(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INSIGHTS
// ============================================================

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  Widget insightCard(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Widget page,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
        child: AppCard(
          child: Row(
            children: [
              Icon(
                icon,
                color: green,
                size: 35,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              color: darkGreen,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          insightCard(
            context,
            Icons.smart_toy_outlined,
            'AI prediction',
            'View sample risk analysis',
            const AIPredictionPage(),
          ),

          insightCard(
            context,
            Icons.notifications_none,
            'Alerts and feedback',
            'Review reminders and suggestions',
            const AlertsPage(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatefulWidget {
  final VoidCallback refresh;

  const ProfilePage({
    super.key,
    required this.refresh,
  });

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Widget profileRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: greyText,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void editProfile() {
    final name =
    TextEditingController(text: currentUser.name);
    final age =
    TextEditingController(text: currentUser.age);
    final weight =
    TextEditingController(text: currentUser.weight);
    final height =
    TextEditingController(text: currentUser.height);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                  ),
                ),
                TextField(
                  controller: age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                  ),
                ),
                TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                  ),
                ),
                TextField(
                  controller: height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                currentUser.name = name.text.trim();
                currentUser.age = age.text.trim();
                currentUser.weight = weight.text.trim();
                currentUser.height = height.text.trim();

                Navigator.pop(dialogContext);

                setState(() {});
                widget.refresh();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkGreen,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 28),

          Center(
            child: Container(
              width: 105,
              height: 105,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Text(
                currentUser.initials,
                style: const TextStyle(
                  color: green,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            currentUser.name.isEmpty
                ? 'HealthGuard User'
                : currentUser.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            currentUser.email.isEmpty
                ? 'user@example.com'
                : currentUser.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: greyText),
          ),

          const SectionTitle('Personal details'),

          AppCard(
            child: Column(
              children: [
                profileRow(
                  'Age',
                  currentUser.age.isEmpty
                      ? 'Not added'
                      : currentUser.age,
                ),
                const Divider(),
                profileRow(
                  'Gender',
                  currentUser.gender.isEmpty
                      ? 'Not added'
                      : currentUser.gender,
                ),
                const Divider(),
                profileRow(
                  'Weight',
                  '${currentUser.weight} kg',
                ),
                const Divider(),
                profileRow(
                  'Height',
                  '${currentUser.height} cm',
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          AppButton(
            'Edit profile',
            editProfile,
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const LoginPage(),
                  ),
                      (route) => false,
                );
              },
              child: const Text(
                'Sign out',
                style: TextStyle(
                  color: red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// HEALTH DATA
// ============================================================

class HealthDataPage extends StatefulWidget {
  const HealthDataPage({super.key});

  @override
  State<HealthDataPage> createState() => _HealthDataPageState();
}

class _HealthDataPageState extends State<HealthDataPage> {
  final sugarController = TextEditingController(text: '98');
  final systolicController = TextEditingController(text: '118');
  final diastolicController = TextEditingController(text: '78');
  final heartController = TextEditingController(text: '72');

  late final TextEditingController weightController =
  TextEditingController(text: currentUser.weight);

  Future<void> saveHealthData() async {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('SIGNED IN UID: ${user?.uid}');
    debugPrint('SIGNED IN EMAIL: ${user?.email}');

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first.'),
        ),
      );
      return;
    }

    final double? bloodSugar =
    double.tryParse(sugarController.text.trim());

    final int? systolic =
    int.tryParse(systolicController.text.trim());

    final int? diastolic =
    int.tryParse(diastolicController.text.trim());

    final int? heartRate =
    int.tryParse(heartController.text.trim());

    final double? weight =
    double.tryParse(weightController.text.trim());

    if (bloodSugar == null ||
        systolic == null ||
        diastolic == null ||
        heartRate == null ||
        weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numbers in all fields.'),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('healthReadings')
          .add({
        'bloodSugar': bloodSugar,
        'systolic': systolic,
        'diastolic': diastolic,
        'heartRate': heartRate,
        'weight': weight,
        'timestamp': FieldValue.serverTimestamp(),
      });

      currentUser.weight = weightController.text.trim();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health data saved successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save health data: $e'),
        ),
      );
    }
  }

  Widget healthInput(
      String title,
      TextEditingController controller,
      String unit,
      ) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: title,
                border: InputBorder.none,
              ),
              style: const TextStyle(
                color: darkGreen,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: greyText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Health data',
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SectionTitle('This morning'),

          healthInput(
            'Blood sugar',
            sugarController,
            'mg/dL',
          ),

          const SizedBox(height: 12),

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Blood pressure',
                  style: TextStyle(color: greyText),
                ),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: systolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '118',
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      child: Text(
                        '/',
                        style: TextStyle(fontSize: 25),
                      ),
                    ),

                    Expanded(
                      child: TextField(
                        controller: diastolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '78',
                        ),
                      ),
                    ),

                    const Text(
                      ' mmHg',
                      style: TextStyle(color: greyText),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          healthInput(
            'Heart rate',
            heartController,
            'bpm',
          ),

          const SizedBox(height: 12),

          healthInput(
            'Weight',
            weightController,
            'kg',
          ),

          const SectionTitle('Earlier'),

          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yesterday, 8:30',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Sugar 112 · Pressure 125/82 · Rate 78',
                  style: TextStyle(color: greyText),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          AppButton(
            'Save and analyse',
            saveHealthData,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTIVITY — ADD ACTIVITY WORKS
// ============================================================

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  void addActivity() {
    final nameController = TextEditingController();
    final minutesController = TextEditingController();
    final caloriesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            25,
            22,
            MediaQuery.of(sheetContext).viewInsets.bottom + 25,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add activity',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Enter the activity you completed.',
                  style: TextStyle(
                    color: greyText,
                  ),
                ),

                const SizedBox(height: 22),

                TextField(
                  controller: nameController,
                  decoration: fieldDecoration(
                    'Activity',
                    'Example: Swimming',
                    Icons.directions_run,
                  ),
                ),

                const SizedBox(height: 13),

                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: fieldDecoration(
                    'Duration',
                    'Minutes',
                    Icons.timer_outlined,
                  ),
                ),

                const SizedBox(height: 13),

                TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: fieldDecoration(
                    'Calories burned',
                    'Example: 250',
                    Icons.local_fire_department_outlined,
                  ),
                ),

                const SizedBox(height: 22),

                AppButton(
                  'Save activity',
                      () async {
                    final name = nameController.text.trim();
                    final minutesText = minutesController.text.trim();
                    final caloriesText = caloriesController.text.trim();

                    if (name.isEmpty || minutesText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter the activity and duration',
                          ),
                        ),
                      );
                      return;
                    }

                    final int? minutes = int.tryParse(minutesText);
                    final int calories =
                        int.tryParse(caloriesText.isEmpty ? '0' : caloriesText) ?? 0;

                    if (minutes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid duration.'),
                        ),
                      );
                      return;
                    }

                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please sign in first.'),
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('activities')
                          .add({
                        'name': name,
                        'minutes': minutes,
                        'calories': calories,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      if (!mounted || !sheetContext.mounted) return;

                      setState(() {
                        activities.add(
                          ActivityEntry(
                            name: name,
                            minutes: minutes.toString(),
                            calories: calories.toString(),
                          ),
                        );
                      });

                      Navigator.pop(sheetContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Activity added successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not save activity: $e'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void deleteActivity(int index) {
    setState(() {
      activities.removeAt(index);
    });
  }

  Widget activityCard(
      ActivityEntry activity,
      int index,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.directions_run,
                color: green,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${activity.minutes} min',
                    style: const TextStyle(
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${activity.calories} kcal',
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    deleteActivity(index);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Activity',
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Steps today',
                        style: TextStyle(color: greyText),
                      ),
                    ),
                    Text(
                      'Goal 10,000',
                      style: TextStyle(color: greyText),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Text(
                  '6,240',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 15),

                LinearProgressIndicator(
                  value: .624,
                  minHeight: 9,
                  color: green,
                  backgroundColor: borderColor,
                ),

                SizedBox(height: 10),

                Text(
                  '3,760 steps left to reach your goal.',
                  style: TextStyle(color: greyText),
                ),
              ],
            ),
          ),

          const SectionTitle('Logged today'),

          if (activities.isEmpty)
            const AppCard(
              child: Text(
                'No activities added yet.',
                style: TextStyle(color: greyText),
              ),
            ),

          ...List.generate(
            activities.length,
                (index) => activityCard(
              activities[index],
              index,
            ),
          ),

          const SizedBox(height: 8),

          AppButton(
            'Add an activity',
            addActivity,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MEALS — ADD MEAL WORKS
// ============================================================

class MealsPage extends StatefulWidget {
  const MealsPage({super.key});

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  int selectedTab = 0;

  CollectionReference<Map<String, dynamic>>? get mealsCollection {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meals');
  }

  void addMeal() {
    final foodController = TextEditingController();
    final caloriesController = TextEditingController();

    String mealType = 'Breakfast';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                25,
                22,
                MediaQuery.of(sheetContext).viewInsets.bottom + 25,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add meal',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: mealType,
                      decoration: fieldDecoration(
                        'Meal type',
                        'Select meal',
                        Icons.restaurant_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Breakfast',
                          child: Text('Breakfast'),
                        ),
                        DropdownMenuItem(
                          value: 'Lunch',
                          child: Text('Lunch'),
                        ),
                        DropdownMenuItem(
                          value: 'Dinner',
                          child: Text('Dinner'),
                        ),
                        DropdownMenuItem(
                          value: 'Snack',
                          child: Text('Snack'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          mealType = value;
                        });
                      },
                    ),

                    const SizedBox(height: 13),

                    TextField(
                      controller: foodController,
                      decoration: fieldDecoration(
                        'Food',
                        'Example: Chicken and rice',
                        Icons.fastfood_outlined,
                      ),
                    ),

                    const SizedBox(height: 13),

                    TextField(
                      controller: caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: fieldDecoration(
                        'Calories',
                        'Example: 520',
                        Icons.local_fire_department_outlined,
                      ),
                    ),

                    const SizedBox(height: 22),

                    AppButton(
                      'Save meal',
                          () async {
                        final String food =
                        foodController.text.trim();

                        final String caloriesText =
                        caloriesController.text.trim();

                        final int? calories =
                        int.tryParse(caloriesText);

                        if (food.isEmpty || calories == null) {
                          ScaffoldMessenger.of(sheetContext)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter the food and valid calories',
                              ),
                            ),
                          );
                          return;
                        }

                        final user =
                            FirebaseAuth.instance.currentUser;

                        if (user == null) {
                          ScaffoldMessenger.of(sheetContext)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please sign in first.',
                              ),
                            ),
                          );
                          return;
                        }
                        debugPrint('========== MEAL DEBUG ==========');
                        debugPrint('SIGNED IN UID: ${user.uid}');
                        debugPrint('SIGNED IN EMAIL: ${user.email}');
                        debugPrint('FOOD: $food');
                        debugPrint('CALORIES: $calories');
                        debugPrint('================================');

                        try {
                          final DocumentReference mealDoc =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('meals')
                              .add({
                            'mealType': mealType,
                            'food': food,
                            'calories': calories,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          debugPrint('MEAL SAVED!');
                          debugPrint('MEAL PATH: ${mealDoc.path}');
                          debugPrint('USER UID: ${user.uid}');
                          debugPrint('USER EMAIL: ${user.email}');

                          if (!mounted) return;

                          setState(() {
                            meals.add(
                              MealEntry(
                                mealType: mealType,
                                food: food,
                                calories: calories.toString(),
                              ),
                            );
                          });

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }

                          if (!mounted) return;

                          ScaffoldMessenger.of(this.context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Meal added successfully',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(this.context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not save meal: $e',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> deleteMeal(String documentId) async {
    final collection = mealsCollection;

    if (collection == null) return;

    try {
      await collection.doc(documentId).delete();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete meal: $e',
          ),
        ),
      );
    }
  }

  Widget mealCard(
      String documentId,
      Map<String, dynamic> data,
      ) {
    final mealType =
    (data['mealType'] ?? 'Meal').toString();

    final food =
    (data['food'] ?? '').toString();

    final calories =
    (data['calories'] ?? 0).toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: lightGold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                color: green,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType,
                    style: const TextStyle(
                      color: darkGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    food,
                    style: const TextStyle(
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              children: [
                Text(
                  '$calories kcal',
                  style: const TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    deleteMeal(documentId);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget todayPage() {
    final collection = mealsCollection;

    if (collection == null) {
      return const Center(
        child: Text(
          'Please sign in to view meals.',
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection
          .orderBy(
        'timestamp',
        descending: true,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Text(
                'Could not load meals:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final documents =
            snapshot.data?.docs ?? [];

        int totalCalories = 0;

        for (final document in documents) {
          final data = document.data();

          final value = data['calories'];

          if (value is num) {
            totalCalories += value.toInt();
          } else {
            totalCalories +=
                int.tryParse(value.toString()) ?? 0;
          }
        }

        double progress = totalCalories / 2000;

        if (progress > 1) {
          progress = 1;
        }

        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Eaten today',
                          style: TextStyle(
                            color: greyText,
                          ),
                        ),
                      ),
                      Text(
                        'Target 2,000',
                        style: TextStyle(
                          color: greyText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$totalCalories',
                    style: const TextStyle(
                      color: darkGreen,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    color: green,
                    backgroundColor: borderColor,
                  ),
                ],
              ),
            ),

            const SectionTitle('Meals'),

            if (documents.isEmpty)
              const AppCard(
                child: Text(
                  'No meals added yet.',
                  style: TextStyle(
                    color: greyText,
                  ),
                ),
              ),

            ...documents.map(
                  (document) => mealCard(
                document.id,
                document.data(),
              ),
            ),

            const SizedBox(height: 8),

            AppButton(
              'Add a meal',
              addMeal,
            ),
          ],
        );
      },
    );
  }

  Widget weekPage() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: const [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly summary',
                style: TextStyle(
                  color: greyText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your weekly summary will use your saved meal data.',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget monthPage() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: const [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly summary',
                style: TextStyle(
                  color: greyText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your monthly summary will use your saved meal data.',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Meals',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              8,
              22,
              5,
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Today'),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Week'),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('Month'),
                ),
              ],
              selected: {selectedTab},
              onSelectionChanged: (selection) {
                setState(() {
                  selectedTab = selection.first;
                });
              },
            ),
          ),

          Expanded(
            child: selectedTab == 0
                ? todayPage()
                : selectedTab == 1
                ? weekPage()
                : monthPage(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI PREDICTION
// ============================================================
class DiabetesPrediction {
  final double probability;
  final int prediction;
  final String riskLevel;

  DiabetesPrediction({
    required this.probability,
    required this.prediction,
    required this.riskLevel,
  });
}

DiabetesPrediction predictDiabetes({
  required double glucose,
  required double bloodPressure,
  required double age,
}) {
  // StandardScaler values learned during model training
  const glucoseMean = 120.90879479;
  const bloodPressureMean = 69.44299674;
  const ageMean = 33.36644951;

  const glucoseScale = 31.53538141;
  const bloodPressureScale = 18.38758897;
  const ageScale = 11.8237979;

  // Logistic Regression coefficients learned during training
  const glucoseCoefficient = 1.17624701;
  const bloodPressureCoefficient = -0.03656406;
  const ageCoefficient = 0.26923407;

  const intercept = -0.7874094753633386;

  final scaledGlucose =
      (glucose - glucoseMean) / glucoseScale;

  final scaledBloodPressure =
      (bloodPressure - bloodPressureMean) /
          bloodPressureScale;

  final scaledAge =
      (age - ageMean) / ageScale;

  final z =
      intercept +
          (glucoseCoefficient * scaledGlucose) +
          (bloodPressureCoefficient * scaledBloodPressure) +
          (ageCoefficient * scaledAge);

  final probability =
      1 / (1 + math.exp(-z));

  final prediction = probability >= 0.5 ? 1 : 0;

  String riskLevel;

  if (prediction == 1) {
    riskLevel = 'Higher predicted risk';
  } else {
    riskLevel = 'Lower predicted risk';
  }

  return DiabetesPrediction(
    probability: probability,
    prediction: prediction,
    riskLevel: riskLevel,
  );
}

class AIPredictionPage extends StatefulWidget {
  const AIPredictionPage({super.key});


  @override
  State<AIPredictionPage> createState() =>
      _AIPredictionPageState();
}

class _AIPredictionPageState
    extends State<AIPredictionPage> {
  late final GenerativeModel aiModel;
  bool isLoading = true;
  String? errorMessage;
  String? aiExplanation;

  double? bloodSugar;
  double? systolic;
  double? diastolic;
  double? heartRate;
  double? weight;
  double? age;

  DiabetesPrediction? diabetesPrediction;
  String analyzeHealth() {
    final List<String> findings = [];

    // Blood sugar analysis
    if (bloodSugar != null) {
      if (bloodSugar! < 70) {
        findings.add('Blood sugar is below the usual range.');
      } else if (bloodSugar! <= 99) {
        findings.add('Blood sugar is within the usual fasting range.');
      } else if (bloodSugar! <= 125) {
        findings.add('Blood sugar is elevated.');
      } else {
        findings.add('Blood sugar is high.');
      }
    }

    // Blood pressure analysis
    if (systolic != null && diastolic != null) {
      if (systolic! < 120 && diastolic! < 80) {
        findings.add('Blood pressure is within the normal range.');
      } else if (systolic! < 130 && diastolic! < 80) {
        findings.add('Blood pressure is elevated.');
      } else {
        findings.add('Blood pressure is above the normal range.');
      }
    }

    // Resting heart rate analysis
    if (heartRate != null) {
      if (heartRate! >= 60 && heartRate! <= 100) {
        findings.add('Heart rate is within the typical resting range.');
      } else {
        findings.add('Heart rate is outside the typical resting range.');
      }
    }

    if (findings.isEmpty) {
      return 'Not enough health data is available for analysis.';
    }

    return findings.join('\n\n');
  }
  @override
  void initState() {
    super.initState();

    aiModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.8-flash',
    );

    loadLatestHealthData();
  }

  Future<void> saveAnalysis(
      DiabetesPrediction result,
      ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('analyses')
        .add({
      'type': 'diabetes',
      'probability': result.probability,
      'percentage':
      double.parse(
        (result.probability * 100).toStringAsFixed(2),
      ),
      'prediction': result.prediction,
      'riskLevel': result.riskLevel,
      'model': 'Logistic Regression',
      'modelAccuracy': 70.78,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  Future<void> generateAIExplanation({
    required double glucose,
    required double systolicBP,
    required double diastolicBP,
    required double heartRateValue,
    required double weightValue,
    required double userAge,
    required DiabetesPrediction prediction,
  }) async {
    try {
      final prompt = '''
You are an educational health assistant inside a student health-tracking app called HealthGuard.

Explain the following health information in simple, supportive language.

User health data:
Age: ${userAge.toStringAsFixed(0)}
Blood glucose: ${glucose.toStringAsFixed(0)} mg/dL
Blood pressure: ${systolicBP.toStringAsFixed(0)}/${diastolicBP.toStringAsFixed(0)} mmHg
Heart rate: ${heartRateValue.toStringAsFixed(0)} bpm
Weight: ${weightValue.toStringAsFixed(1)} kg

Machine learning analysis:
Model: Logistic Regression
Model accuracy in our test set: 70.78%
Estimated diabetes probability: ${(prediction.probability * 100).toStringAsFixed(2)}%
Classification: ${prediction.riskLevel}

Instructions:
- Explain what the machine learning result means.
- Do not diagnose diabetes or any other medical condition.
- Clearly state that this is an educational prototype and not a medical diagnosis.
- Give 2 or 3 short general wellness recommendations.
- Do not invent additional health measurements.
- Recommend professional medical advice if the user has health concerns.
- Keep the response concise and easy to understand.
''';

      final response = await aiModel.generateContent([
        Content.text(prompt),
      ]);

      if (!mounted) return;

      setState(() {
        aiExplanation =
            response.text ?? 'No AI explanation was generated.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        aiExplanation = 'Could not generate AI explanation: $e';
      });
    }
  }
  Future<void> loadLatestHealthData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Please sign in first.';
      });
      return;
    }

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDocument.data();

      final loadedAge = double.tryParse(
        userData?['age']?.toString() ?? '',
      );
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('healthReadings')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage =
          'No health readings were found.';
        });
        return;
      }

      final data = snapshot.docs.first.data();

      final loadedBloodSugar =
      (data['bloodSugar'] as num?)?.toDouble();

      final loadedSystolic =
      (data['systolic'] as num?)?.toDouble();

      final loadedDiastolic =
      (data['diastolic'] as num?)?.toDouble();

      final loadedHeartRate =
      (data['heartRate'] as num?)?.toDouble();

      final loadedWeight =
      (data['weight'] as num?)?.toDouble();

      DiabetesPrediction? predictionResult;

      if (loadedBloodSugar != null &&
          loadedDiastolic != null &&
          loadedAge != null) {
        predictionResult = predictDiabetes(
          glucose: loadedBloodSugar,
          bloodPressure: loadedDiastolic,
          age: loadedAge,
        );
      }
      if (predictionResult != null) {
        await saveAnalysis(predictionResult);
      }
      if (predictionResult != null &&
          loadedBloodSugar != null &&
          loadedSystolic != null &&
          loadedDiastolic != null &&
          loadedHeartRate != null &&
          loadedWeight != null &&
          loadedAge != null) {
        await generateAIExplanation(
          glucose: loadedBloodSugar!,
          systolicBP: loadedSystolic,
          diastolicBP: loadedDiastolic!,
          heartRateValue: loadedHeartRate,
          weightValue: loadedWeight,
          userAge: loadedAge!,
          prediction: predictionResult,
        );
      }


      setState(() {
        bloodSugar = loadedBloodSugar;
        systolic = loadedSystolic;
        diastolic = loadedDiastolic;
        heartRate = loadedHeartRate;
        weight = loadedWeight;
        age = loadedAge;

        diabetesPrediction = predictionResult;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
        'Could not load health data: $e';
      });
    }
  }

  Widget healthValue(
      String title,
      String value,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: lightGreen,
            child: Icon(
              icon,
              color: green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: darkGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: darkGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'AI prediction',
      child: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: green,
        ),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: greyText,
            ),
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius:
              BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: green,
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health data loaded',
                        style: TextStyle(
                          color: green,
                          fontSize: 19,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Using your latest Firebase health reading.',
                        style: TextStyle(
                          color: greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle(
            'Latest health data',
          ),

          AppCard(
            child: Column(
              children: [
                healthValue(
                  'Blood sugar',
                  '${bloodSugar?.toStringAsFixed(0) ?? '--'} mg/dL',
                  Icons.water_drop_outlined,
                ),
                healthValue(
                  'Blood pressure',
                  '${systolic?.toStringAsFixed(0) ?? '--'}/${diastolic?.toStringAsFixed(0) ?? '--'} mmHg',
                  Icons.favorite_outline,
                ),
                healthValue(
                  'Heart rate',
                  '${heartRate?.toStringAsFixed(0) ?? '--'} bpm',
                  Icons.monitor_heart_outlined,
                ),
                healthValue(
                  'Weight',
                  '${weight?.toStringAsFixed(1) ?? '--'} kg',
                  Icons.monitor_weight_outlined,
                ),
              ],
            ),
          ),
          const SectionTitle(
            'Diabetes prediction',
          ),

          AppCard(
            child: diabetesPrediction == null
                ? const Text(
              'Not enough data to calculate a prediction.',
              style: TextStyle(
                color: greyText,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Model-estimated probability',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${(diabetesPrediction!.probability * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: darkGreen,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                LinearProgressIndicator(
                  value: diabetesPrediction!.probability,
                  minHeight: 9,
                  color: diabetesPrediction!.prediction == 1
                      ? gold
                      : green,
                  backgroundColor: borderColor,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(
                      diabetesPrediction!.prediction == 1
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: diabetesPrediction!.prediction == 1
                          ? gold
                          : green,
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        diabetesPrediction!.riskLevel,
                        style: const TextStyle(
                          color: darkGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionTitle('AI explanation'),

          AppCard(
            child: aiExplanation == null
                ? const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: green,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Generating your AI explanation...',
                    style: TextStyle(
                      color: greyText,
                    ),
                  ),
                ),
              ],
            )
                : Text(
              aiExplanation!,
              style: const TextStyle(
                color: darkGreen,
                height: 1.5,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ALERTS
// ============================================================

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  Widget alert(
      IconData icon,
      String title,
      String text,
      Color iconColor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 30,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    text,
                    style: const TextStyle(
                      color: greyText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Alerts & feedback',
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SectionTitle('Needs attention'),

          alert(
            Icons.warning_amber_rounded,
            'Blood pressure above range',
            'Your previous demo reading was 125/82.',
            red,
          ),

          alert(
            Icons.directions_walk,
            'Step goal not met',
            'You currently have 6,240 of 10,000 steps.',
            gold,
          ),

          alert(
            Icons.restaurant_outlined,
            'Meal reminder',
            'Remember to keep your meal log up to date.',
            gold,
          ),

          alert(
            Icons.monitor_heart_outlined,
            'Weekly check-in',
            'Update your weight and health readings for your weekly report.',
            green,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARE TEAM
// ============================================================

class CareTeamPage extends StatefulWidget {
  const CareTeamPage({super.key});

  @override
  State<CareTeamPage> createState() => _CareTeamPageState();
}

class _CareTeamPageState extends State<CareTeamPage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Care team',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              5,
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Doctors'),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Appointments'),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('Reports'),
                ),
              ],
              selected: {selectedTab},
              onSelectionChanged: (selection) {
                setState(() {
                  selectedTab = selection.first;
                });
              },
            ),
          ),

          Expanded(
            child: selectedTab == 0
                ? const DoctorsPage()
                : selectedTab == 1
                ? const AppointmentsPage()
                : const ReportsPage(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DOCTORS — CHAT AND BOOK WORK
// ============================================================

class DoctorsPage extends StatelessWidget {
  const DoctorsPage({super.key});

  Widget doctorCard(
      BuildContext context,
      String initials,
      String name,
      String specialty, [
        String doctorUid = '',
      ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: lightGreen,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: darkGreen,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        specialty,
                        style: const TextStyle(
                          color: greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorChatPage(
                            doctorName: name,
                            initials: initials,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                    ),
                    label: const Text('Chat'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: doctorUid.isEmpty ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingPage(
                            doctorName: name,
                            doctorUid: doctorUid,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                    ),
                    label: const Text('Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        doctorCard(
          context,
          'AK',
          'Dr Ahmed Khalil',
          'Internal medicine',
          '9W8v9jNlQFeyYroPXgc0ibv3DJl2',
        ),

        doctorCard(
          context,
          'RL',
          'Dr Rania Lotfy',
          'Endocrinology',
        ),

        doctorCard(
          context,
          'MH',
          'Dr Mona Hassan',
          'Cardiology',
        ),

        const SectionTitle('About care team'),

        const AppCard(
          child: Text(
            'The doctors and conversations shown here are demo content for the prototype.',
            style: TextStyle(
              color: greyText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DOCTOR CHAT — SEND + DEMO REPLY
// ============================================================

class DoctorChatPage extends StatefulWidget {
  final String doctorName;
  final String initials;

  const DoctorChatPage({
    super.key,
    required this.doctorName,
    required this.initials,
  });

  @override
  State<DoctorChatPage> createState() =>
      _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  final messageController = TextEditingController();

  late List<ChatMessage> messages;

  bool doctorTyping = false;

  @override
  void initState() {
    super.initState();

    messages = [
      ChatMessage(
        text:
        'Hello ${currentUser.firstName}. How can I help you today?',
        mine: false,
      ),
    ];
  }

  void sendMessage() {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(
        ChatMessage(
          text: text,
          mine: true,
        ),
      );

      doctorTyping = true;
    });

    messageController.clear();

    Timer(
      const Duration(seconds: 1),
          () {
        if (!mounted) return;

        setState(() {
          doctorTyping = false;

          messages.add(
            ChatMessage(
              text:
              'Thanks for your message. I have received it. Please continue tracking your readings and let me know if you have another question.',
              mine: false,
            ),
          );
        });
      },
    );
  }

  Widget bubble(ChatMessage message) {
    return Align(
      alignment: message.mine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: message.mine
              ? green
              : Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: message.mine
              ? null
              : Border.all(
            color: borderColor,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.mine
                ? Colors.white
                : darkGreen,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: widget.doctorName,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: lightGreen,
                  child: Text(
                    widget.initials,
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                const Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo conversation',
                      style: TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Simulated replies',
                      style: TextStyle(
                        color: greyText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...messages.map(bubble),

                if (doctorTyping)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Doctor is typing...',
                        style: TextStyle(
                          color: greyText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Write a message',
                        filled: true,
                        fillColor: background,
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) {
                        sendMessage();
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(
                    backgroundColor: green,
                    child: IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOOK APPOINTMENT
// ============================================================

class BookingPage extends StatefulWidget {
  final String doctorName;
  final String doctorUid;

  const BookingPage({
    super.key,
    required this.doctorName,
    this.doctorUid = '',
  });

  @override
  State<BookingPage> createState() =>
      _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> chooseDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: now.add(
        const Duration(days: 1),
      ),
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 365),
      ),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> chooseTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 10,
        minute: 0,
      ),
    );

    if (result != null) {
      setState(() {
        selectedTime = result;
      });
    }
  }

  Future<void> confirmBooking() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose a date and time',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in first.',
          ),
        ),
      );
      return;
    }

    try {
      final appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .add({
        'doctorName': widget.doctorName,
        'doctorUid': widget.doctorUid,
        'patientUid': user.uid,
        'appointmentDateTime':
        Timestamp.fromDate(appointmentDateTime),
        'status': 'Booked',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        appointments.add(
          AppointmentEntry(
            doctor: widget.doctorName,
            date: selectedDate!,
            time: selectedTime!,
          ),
        );
      });

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: green,
              size: 55,
            ),
            title: const Text(
              'Appointment booked',
            ),
            content: Text(
              'Your appointment with ${widget.doctorName} has been saved.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save appointment: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Book appointment',
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          AppCard(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: lightGreen,
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: green,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    widget.doctorName,
                    style: const TextStyle(
                      color: darkGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle('Choose date'),

          InkWell(
            onTap: chooseDate,
            child: AppCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: green,
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'Select a date'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: TextStyle(
                        color: selectedDate == null
                            ? greyText
                            : darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                    color: greyText,
                  ),
                ],
              ),
            ),
          ),

          const SectionTitle('Choose time'),

          InkWell(
            onTap: chooseTime,
            child: AppCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: green,
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Text(
                      selectedTime == null
                          ? 'Select a time'
                          : selectedTime!.format(context),
                      style: TextStyle(
                        color: selectedTime == null
                            ? greyText
                            : darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                    color: greyText,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          AppButton(
            'Confirm booking',
            confirmBooking,
          ),

          const SizedBox(height: 14),

          const Text(
            'This creates a local demo appointment only. It is not sent to a real clinic or doctor.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: greyText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// APPOINTMENTS
// ============================================================

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() =>
      _AppointmentsPageState();
}

class _AppointmentsPageState
    extends State<AppointmentsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SectionTitle('Your appointments'),

        if (appointments.isEmpty)
          const AppCard(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: green,
                  size: 45,
                ),
                SizedBox(height: 12),
                Text(
                  'No appointments booked yet',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Go to Doctors and press Book.',
                  style: TextStyle(
                    color: greyText,
                  ),
                ),
              ],
            ),
          ),

        ...List.generate(
          appointments.length,
              (index) {
            final appointment =
            appointments[index];

            return Padding(
              padding:
              const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: green,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.doctor,
                            style: const TextStyle(
                              color: darkGreen,
                              fontSize: 17,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}',
                            style: const TextStyle(
                              color: greyText,
                            ),
                          ),
                          Text(
                            appointment.time
                                .format(context),
                            style: const TextStyle(
                              color: green,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          appointments
                              .removeAt(index);
                        });
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// REPORTS
// ============================================================

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  Widget report(
      String title,
      String subtitle,
      String status,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: green,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ),

            Chip(
              label: Text(status),
              backgroundColor: lightGreen,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SectionTitle('Health reports'),

        report(
          'April health summary',
          '12 readings',
          'Reviewed',
        ),

        report(
          'Blood pressure log',
          '9 readings',
          'Ready',
        ),

        report(
          'March health summary',
          '24 readings',
          'Reviewed',
        ),

        const SectionTitle('New report'),

        const AppCard(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'This week’s summary',
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Includes your recent health readings, activities and meals.',
                style: TextStyle(
                  color: greyText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        AppButton(
          'Share report',
              () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Demo report prepared for sharing',
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        const Text(
          'Report sharing is simulated in this prototype.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: greyText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}