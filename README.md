# Food Delivery App

A Flutter-based food delivery application template featuring product listing, search, favorites, cart, authentication, and admin product management.

This repository contains a cross-platform Flutter app (Android, iOS, web, desktop) built with Flutter and Supabase integration for backend services. It is organized with riverpod providers, models, screens, and tabs to demonstrate a scalable app structure.

## Table of contents

- Features
- Screens / Modules
- Getting started
	- Prerequisites
	- Setup
	- Environment variables
	- Run (mobile / web)
- Testing
- Project structure
- Contributing
- License
- Contact


## Features

- User authentication (login, signup, splash)
- Product listing and details
- Search and categories
- Favorites (bookmark products)
- Cart with add/remove/update item quantity
- Admin screens for product management (create/edit)
- Supabase integration for backend/data storage
- Image assets and local storage helper


## Screens / Modules

- Authentication: `login`, `signup`, `splash`
- Main tabs: `home`, `search`, `favorites`, `cart`, `profile`
- Admin: `product list`, `product form` (create/edit)
- Providers: central state management for auth, products, cart, favorites, tabs


## Getting started

### Prerequisites

- Flutter (stable) — see https://flutter.dev for installation instructions
- Dart SDK (bundled with Flutter)
- Android Studio / Xcode (for mobile emulators) or Chrome for web
- Optional: Supabase account if you plan to use the included Supabase provider


### Setup

1. Clone the repository

	 git clone https://github.com/tahmidulislamfahim/food_delivery_app.git
	 cd food_delivery_app

2. Install packages

	 flutter pub get

3. Provide environment/configuration variables (see below)


### Environment variables

This project uses Supabase (optional). Create a `.env` file or set environment variables in your platform's secure storage. Example variables used by the project (names may vary depending on how you wire them up in `supabase_provider.dart`):

- SUPABASE_URL=your-supabase-url
- SUPABASE_ANON_KEY=your-supabase-anon-key

Important: Do not commit sensitive keys to the repository. Use GitHub Secrets for CI or `.gitignore` to prevent accidental commits.


### Run

Run on an Android emulator or connected device:

```powershell
# get packages
flutter pub get

# run on connected device (Android/iOS)
flutter run
```

Run for web:

```powershell
flutter run -d chrome
```


## Testing

There is a basic widget test included in `test/widget_test.dart`. Run tests with:

```powershell
flutter test
```


## Project structure

- `lib/` — main app source
	- `main.dart` — app entrypoint
	- `app/` — app-level widget(s)
	- `auth/` — authentication screens and services
	- `tabs/`, `screens/` — UI screens
	- `providers/` — state management and data providers
	- `models/` — data models
	- `admin/` — admin screens and helpers
- `assets/` — images and other static assets
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` — platform folders


## Contributing

Contributions are welcome. A suggested workflow:

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make changes and add tests if applicable
4. Commit and push: `git push origin feat/my-feature`
5. Open a pull request describing your changes

Please follow existing code style and include tests for new behavior where possible.


## License

This project does not include a license file. If you plan to publish this repository, add a `LICENSE` file (for example, MIT) to make usage terms explicit.


## Contact

If you have questions or want to collaborate, open an issue or contact the repository owner on GitHub: https://github.com/tahmidulislamfahim

---