# Workforce Management UI (Flutter)

Pixel-perfect Flutter implementation of the dark Workforce dashboard shown in the reference images.  
The app follows an **MVC + Provider** structure, uses **Firebase (Auth-ready + Cloud Firestore)**, and includes a chat/task/team workspace with desktop styling.

## Highlights
- Custom sidebar navigation with Tasks, Team, and Chat sections.
- Modular controllers + providers that load data from Firestore and gracefully fall back to seeded sample data.
- Firebase wiring already in place (`firebase_core`, `cloud_firestore`, `firebase_auth`) with a `DefaultFirebaseOptions` shim for easy replacement.
- Widget tests run with a fake data service (no Firebase dependency during CI).

## Folder Structure
```
lib/
├── app.dart
├── main.dart
├── config/          # Theme + shared configuration
├── constants/       # Colors, spacing, typography helpers
├── controllers/     # Task/Team/Chat controllers (MVC)
├── data/            # Sample data seeds
├── models/          # Strongly typed models
├── providers/       # Provider(s) that bridge controllers + UI
├── services/        # Firebase service wrapper
└── views/           # UI layer (Tasks/Team/Chat + shared widgets)
```

## Firebase Setup
1. Install the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) if you have not already.
2. Run `flutterfire configure` from the project root and select your Firebase project.
3. Replace the placeholder values inside `lib/firebase_options.dart` with the generated content (or keep the generated file directly).
4. Add the native config files supplied by Firebase to each platform:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `macos/Runner/GoogleService-Info.plist`
   - `web/firebase-messaging-sw.js`, etc. (if applicable)
5. Optional: seed Firestore with `tasks`, `team`, and `conversations` collections that match the sample model fields. The UI already handles empty/failed loads by reverting to the mock data.

## Running & Testing
```bash
flutter pub get
flutter run        # launches the UI
flutter test       # runs widget tests (uses fake Firebase service)
```

> **Note:** During development the UI will render sample data until Firestore returns real records. Update the controllers/services if you need to write mutations tailored to your schema.

## Git Workflow
1. Create a collaboration branch once you finish configuring Firebase:
   ```bash
   git checkout -b feature/workforce-dashboard
   git add .
   git commit -m "feat: implement workforce dashboard with MVC + Firebase"
   git push origin feature/workforce-dashboard
   ```
2. Share the branch with your teammates to continue development (auth flows, Firestore writes, etc.).

---
Questions / tweaks? Let me know and I can adjust the layout, add auth, or wire additional Firestore queries.
