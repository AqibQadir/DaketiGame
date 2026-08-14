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
