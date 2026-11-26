# Firebase configuration

Configure Firebase Authentication, Cloud Firestore, Firebase AI Logic and App Check in the authorized Firebase project. The repository contains the project’s [Firestore rules](firestore.rules).

Firestore stores user records under `users/{uid}` with `healthReadings`, `activities`, `meals`, `analyses`, and `appointments` subcollections. Doctor accounts require administrator-managed role assignment. The existing rules allow assigned appointment reads but do not authorize doctor access to patient health records.

Keep Firebase credentials, debug secrets and signing keys out of the repository.
