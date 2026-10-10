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
#   cd ../TIIPE/backend && venv/bin/python manage.py shell < /path/to/tool/qa_seed.py
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d <simulator-id> \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1
# Screenshots land in build/screenshots. Remove the data afterwards with tool/qa_clean.py.
```

## Before release

- App icons and splash screen (the brand files are in `assets/images/`).
- Bundle id `com.thenovatrix.novatrix_app`: confirm, then set up signing (Apple team, Android keystore).
- Production `API_BASE_URL` and `SITE_URL`.
- Privacy policy URL and data-safety answers for the stores (the app stores only the login session on
  the device).
- Push notifications (review feedback, announcements, ticket updates) are a good next step; they
  need Firebase/APNs set up.
