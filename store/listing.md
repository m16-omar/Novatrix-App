# Store listing: Novatrix

Text and answers for App Store Connect and the Google Play Console. Check the bracketed items before you submit.

## Basics

| | |
|---|---|
| App name | Novatrix |
| Subtitle (iOS, 30 chars) | Software, systems and training |
| Bundle ID / package name | `com.thenovatrix.app` (both stores) |
| Version | 1.0.0 (build 1), from `version:` in `pubspec.yaml` |
| Category | Education (secondary: Business) |
| Age rating | 4+ / Everyone (no objectionable content, no user-to-user chat, no purchases in the app) |
| Price | Free |
| Support URL | https://thenovatrix.com/contact |
| Marketing URL | https://thenovatrix.com |
| Privacy policy URL | https://thenovatrix.com/legal/privacy-policy |
| Support email | hello@thenovatrix.com |

## Short description (Google Play, 80 chars)

Learn tech skills in live cohorts and follow your Novatrix projects on the go.

## Promotional text (iOS, 170 chars)

Take your Novatrix courses with you: lessons, assignments and feedback, certificates, and your client projects and support requests, all in one app.

## Description

Novatrix designs software, implements digital systems, and trains people to use technology effectively. The Novatrix app brings your learning and your projects into one place.

LEARN
• Browse live, cohort-based courses in data analytics, data science, web development, and cloud and DevOps
• Follow your lessons, open videos and resources, and mark lessons complete
• Submit assignments and read your facilitator's feedback
• Keep track of your progress and your certificates of completion

FOR FACILITATORS
• See the work waiting for review across your courses
• Follow your learners' progress and issue certificates

FOR CLIENTS
• Follow each stage of your project
• Open shared documents and read project updates
• Raise and track support requests

EXPLORE NOVATRIX
• Our services: custom software, system implementation, systems integration, and support
• Corporate training and youth and workforce programs
• Solutions for education, healthcare, nonprofits, SMEs, the public sector, and media
• Practical guides from our team
• Request a consultation or a training proposal

NOTIFICATIONS
• Get notified when your facilitator reviews your work, when your course posts an announcement, and when we update your support request

One account works on the app and on thenovatrix.com.

## Keywords (iOS, 100 chars)

tech training,courses,data analytics,web development,cloud,cohort,certificate,software,projects

## App Review notes (iOS) and app access (Google Play)

Most of the app needs an account. Give reviewers a working one:

```
Email:    [reviewer account email]
Password: [reviewer account password]
```

[Create this account on the production backend. Enroll it in at least one course with a few lessons, and add it to a client project, so reviewers can see the learning and client areas. Facilitator access is optional.]

Notes for Apple:
> Courses are live, instructor-led cohorts. Learners pay for enrollment on our payment provider's page in the browser; free courses enroll directly. People who enrolled on the website see their courses in the app.
>
> Account deletion: Profile > Delete my account. This sends a deletion request to our team, which deletes the account and confirms by email.

## App Privacy (App Store Connect)

- Tracking: **No**. The app has no analytics, advertising, or tracking SDKs.
- Data collected, all **linked to the user**, none used for tracking:
  - Contact info: name, email address, phone number. Used for app functionality and customer support.
  - User content: assignment submissions, support requests, and enquiry messages. Used for app functionality.
  - Identifiers: user ID. Used for app functionality.
- Not collected: location, contacts, photos, health, financial info, browsing history, usage data, diagnostics.

## Data safety (Google Play)

- Data collected: name, email address, phone number (optional); other user-generated content (assignment submissions, support requests, messages); user IDs.
- Purpose: app functionality, account management, and communications (replying to requests).
- Shared with third parties: **No**.
- Encrypted in transit: **Yes** (HTTPS only).
- Users can request deletion: **Yes**, in the app (Profile > Delete my account) or by emailing hello@thenovatrix.com.
- Optional collection: phone number and enquiry details.

## Screenshots

Required: iPhone 6.9" (1320 × 2868), and Google Play phone screenshots (at least 2; 1080 × 1920 or larger). The app is iPhone-only, so no iPad screenshots are needed.

Suggested set, signed in as the reviewer account against production:
1. Home
2. Course page
3. Learning dashboard
4. Lesson
5. Client project tracker
6. A service page (for example, System Implementation)

## Before each upload

1. Bump `version:` in `pubspec.yaml`. The build number after `+` must go up every time.
2. `API_BASE_URL=https://… tool/build_release.sh`
3. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console, and `build/ios/ipa/*.ipa` with Transporter or Xcode Organizer.
