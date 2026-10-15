# Novatrix-App

Software that works. Systems that scale. Training that lasts. The official mobile application for The Novatrix.

Built with Flutter (iOS and Android). It uses the same backend and database as the website
(thenovatrix.com): the TIIPE & Novatrix Django API, with every request sent as `X-Tenant: novatrix`.
Accounts, courses, progress, certificates, projects, and tickets are shared between the app and the
website.

## What's in the app

| Area | Screens |
|---|---|
| Public | Home, course catalog and course pages (live prices and syllabus), consultation request |
| Accounts | Log in as learner, facilitator, or client; sign up; password reset (link opens the website) |
| Learning | Dashboard, my courses, course player (lessons, video and resource links, mark complete, assignment submission and feedback), certificates, orders |
| Teaching | Dashboard, review queue across all courses (review and request revisions), learners with certificate issuing |
| Client | Dashboard with project stage tracker, projects, project documents and updates, support tickets, new request |
| Profile | Details, edit details, change password, switch between areas, light/dark/system theme, log out |

The bottom navigation follows the area you're in, like the website's header. People with several
roles switch areas from the label next to the logo or from Profile.

Not in the app on purpose:
- **Buying courses.** Course pages link to checkout on the website. Selling digital courses inside an
  iOS or Android app would require Apple/Google in-app purchase.
- **Course authoring.** Facilitators build lessons and post announcements on the website.

## Project layout

```
lib/
  core/        config, API client (JWT + refresh), providers, router, theme, shared widgets
  data/        models and repositories, one per area (auth, catalog, learning, teaching, portal)
  features/    screens: public, auth, learner, teaching, client, profile, shell (navigation)
integration_test/  end-to-end journey with screenshots
tool/          QA seed/cleanup scripts for the journey test
```

State is Riverpod 3, navigation is go_router, HTTP is Dio. Tokens are stored in the iOS Keychain /
Android Keystore (flutter_secure_storage).

## Running

Requires Flutter 3.38+ (Dart 3.10). iOS 15+, Android 5+.

```bash
flutter pub get
flutter run                                   # local backend at localhost:8000 (10.0.2.2 on Android)
flutter run --dart-define=API_BASE_URL=https://<api-host>/api/v1
```

| Setting | Default | Purpose |
|---|---|---|
| `API_BASE_URL` | `http://localhost:8000/api/v1` | The shared backend |
| `SITE_URL` | `https://thenovatrix.com` | Checkout, certificates, password reset, legal pages |

Release builds must use an `https` API URL (iOS and Android block plain http outside debug).

## Tests

```bash
flutter analyze
flutter test                                  # unit tests

# End-to-end on a simulator against a local backend with QA data:
#   cd ../../TIIPE/backend && venv/bin/python manage.py shell < /path/to/tool/qa_seed.py
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d <simulator-id> \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1
# Screenshots land in build/screenshots. Remove the data afterwards with tool/qa_clean.py.
```

## Website content

The services, training programs, solutions, industries, and insights articles come from thenovatrix.com and
are bundled in `assets/content/site.json`. Refresh them after the website changes, then run `flutter test`
(it checks the content's internal links):

```bash
node tool/sync_site_content.js
```

The home and About page copy (hero, mission, values, impact figures, testimonials, policies) is written into
the website's page layouts rather than its data, so it is kept by hand in `lib/data/site_content.dart`.

## Releasing

Store text, privacy answers, and review notes: [store/listing.md](store/listing.md).

```bash
API_BASE_URL=https://<production api>/api/v1 tool/build_release.sh   # android | ios | all
```

A release build refuses to start without an `https` `API_BASE_URL`, so a store build can never point at a
development server. Bump `version:` in `pubspec.yaml` before every upload.

- **App ID:** `com.thenovatrix.app` on both stores. It can't change after the first release.
- **iOS signing:** automatic, with the Apple team in the Xcode project. The app is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`).
- **Android signing:** `android/key.properties` (not in git) points at the upload keystore. If it's missing,
  release builds fall back to debug signing, which Play rejects. Back up the keystore and its password: losing
  them means asking Google to reset the upload key.
- **Icons:** generated from `design/icon/` with `dart run flutter_launcher_icons`.
- **Paying for courses on iOS:** the cart's "Enroll now" opens the payment page on iOS too, by choice. Apple
  may reject this under guideline 3.1.1 (outside payment for digital services used in the app). If it does,
  switch `AppConfig.allowsWebCheckout` off for iOS: the iOS cart then sends an enrollment enquiry instead.
- **Account deletion:** Profile > Delete my account sends a request to the team through the website's
  contact form (`/cms/contact/`). Someone must act on these requests. A backend endpoint that deletes the
  account directly would be better.

## Push notifications

The app gets a push when a facilitator reviews an assignment, when a course posts an announcement, and when
staff update a client's support ticket. Tapping one opens that lesson, course, or the Support tab. The backend
sends them (`apps/notifications/push.py`, `apps/novatrix_services/push_events.py` in TIIPE/backend).

Push needs Firebase on the app side and a Firebase service account on the backend; without them it's
simply off. Setup:

1. **Firebase project:** done. The app uses project `tiipe-17751`; the iOS and Android app IDs and their
   API keys are built into `lib/core/push.dart` (they identify the app, they aren't secrets). There's no need
   to add `GoogleService-Info.plist` or `google-services.json` to the project.
2. **APNs key (iOS):** in the Apple Developer account, Keys > create a key with Apple Push Notifications
   service, then upload the `.p8` in Firebase > Project settings > Cloud Messaging > Apple app configuration.
3. **Backend:** Firebase > Project settings > Service accounts > Generate new private key. Set
   `FIREBASE_CREDENTIALS` on the backend to that file's path or its JSON, and `pip install -r requirements.txt`.
   Keep that file out of git: it's a secret.
4. **Other Firebase projects** (staging, say): override the built-in values at build time with
   `--dart-define=FIREBASE_API_KEY=… FIREBASE_ANDROID_API_KEY=… FIREBASE_PROJECT_ID=… FIREBASE_SENDER_ID=…
   FIREBASE_IOS_APP_ID=… FIREBASE_ANDROID_APP_ID=…`; `tool/build_release.sh` passes them through when they're set.

iOS pushes need the APNs key (step 2); test them on a real phone.

## Later

- Saving courses and projects for offline viewing.
