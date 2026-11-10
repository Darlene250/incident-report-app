# Campus Incident Reporting

A Flutter + Firebase app for ALU students and staff to report campus issues
(facilities, water, electricity, safety, sanitation), follow them through
**Submitted → In Progress → Resolved**, and let staff update their status.

The full technical write-up is in [docs/TECHNICAL_REPORT.md](docs/TECHNICAL_REPORT.md).

## Features

| Area | What it does |
|------|--------------|
| Authentication | Register, sign in, sign out, forgot password, session restore. Only `@alustudent.com`, `@alueducation.com` and `@aluedu.com` emails are accepted. Student domains must verify their email before the app opens; `@aluedu.com` accounts are created as staff and skip verification. |
| Reporting | Category, title, description, campus location, optional photo from the camera or gallery (compressed on the device and stored in Firestore) and an option to report anonymously. |
| Browsing | All reports with live search plus status and category filters. |
| Details | Summary, photo, status timeline with timestamps, reporter (or "Reported anonymously"). |
| Student actions | Edit or delete their own report while it is still *Submitted*. |
| Staff actions | Move any report between *Submitted*, *In Progress* and *Resolved*. |
| My Reports | The user's own reports with counters and a status filter. |

## Architecture

```
lib/
  core/        constants, theme, validators, error messages, reusable widgets
  models/      Incident, StatusChange, AppUser (Firestore <-> Dart mapping)
  services/    AuthService, IncidentService (only layer that calls Firebase)
  providers/   AuthProvider, IncidentProvider (ChangeNotifier state, business rules)
  screens/     auth, home, reports, report_form, details, profile
```

UI → Provider → Service → Firebase. Screens never call Firebase directly.

## Running

```shell
flutter pub get
flutter run            # pick an Android/iOS device or Chrome
flutter test           # 102 unit and widget tests
flutter analyze
```

### Security rules tests

`rules_test/` runs 48 checks of `firestore.rules` against the local Firestore
emulator (needs the Firebase CLI, Node and Java; it never touches the live
project):

```shell
cd rules_test
npm install
npm test
```

## Firebase setup

The app is connected to the Firebase project `incident-report-app-f49b9`.
Generated configuration lives in `lib/firebase_options.dart`,
`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.

1. **Authentication** → enable *Email/Password*.
2. **Firestore** → create the database, then deploy the rules:
   `firebase deploy --only firestore:rules`
3. No Cloud Storage is needed. Photos are stored in Firestore, so the project
   runs on the free **Spark** plan.

### Making a staff account

Register with an `@aluedu.com` address. The account is created with the
`staff` role and goes straight into the app, with no verification email.

Accounts on other domains are created as `student`, and the rules stop users
from changing their own role. To promote one of them, open
**Firestore → users → {uid}** in the Firebase Console and set `role` to
`staff`. The user then taps **Retry** or signs in again.
