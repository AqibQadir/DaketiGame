# Daketi Phase I Flutter Project

A modular, feature-first Flutter UI project based on the supplied Daketi Phase I Figma screens.

## Included supplied images

- `assets/images/background1.png` — bike rider and police chase
- `assets/images/background2.png` — Chai Hotel rainy street

## Image mapping

`background1.png` is used on:
- Splash
- Terms & Conditions
- Privacy Policy

`background2.png` is used on:
- Welcome
- Login/Signup selection
- Login
- Signup
- Home
- Settings
- Profile
- Support

## Project structure

```text
lib/
├── app/
├── core/
│   ├── constants/
│   ├── routes/
│   ├── theme/
│   └── widgets/
├── features/
│   ├── splash/
│   ├── legal/
│   ├── auth/
│   ├── home/
│   ├── settings/
│   ├── profile/
│   └── support/
└── main.dart
```

## Run

```bash
flutter pub get
flutter run
```

The app is locked to landscape orientation to match the Figma frames. Material icons are temporary placeholders until the custom Figma icons and logo are supplied.

## Backend integration

The app uses `https://game.daketi.pk` for REST and WebSocket-only Socket.io.
Accounts, solo/multiplayer, reconnect, leaderboard/history, waitlist and referrals
are wired to the API guide. Guest games remain available; signed-in users follow
server `canPlay` eligibility.

See [API integration and provider setup](docs/api-guide-integration.md) for Meta,
Firebase, deep-link configuration, tested behavior, and remaining backend checks.
Facebook and push are opt-in until their real provider configuration is supplied.
No payment, wallet or chat backend is supplied by this guide.

```sh
flutter analyze
flutter test
flutter build apk --debug
# Public backend diagnostics (no account or game creation):
dart run tool/backend_smoke.dart
```

Override the server for staging with
`flutter run --dart-define=DAKETI_SERVER_URL=https://your-staging-server`.
