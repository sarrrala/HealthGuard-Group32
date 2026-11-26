# Firebase configuration

`firestore.rules` is the supplied rules snapshot, not a new access-control policy. Do not deploy it blindly over newer working rules.

Use the original Android project and its authorized Firebase configuration. Enable email/password authentication, configure Firestore and Firebase AI Logic, and register development App Check debug secrets privately in Firebase Console. Use an appropriate production attestation provider for release builds. Never commit debug secrets.

Firestore paths: `users/{uid}` with `healthReadings`, `activities`, `meals`, `analyses`, and `appointments` subcollections. Doctor accounts require administrator-managed role assignment. Existing rules permit assigned appointment reads but not doctor access to patient health data. Implement explicit authorized doctor–patient relationships and test both allowed and denied access before extending permissions.
