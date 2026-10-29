# ShareLoop

A Flutter app for **ShareLoop** — a recycling & item-sharing platform for
Sri Lanka ("Give What You Don't Need. Get What You Do."), backed by a PHP
Laravel API in [`backend/`](backend/README.md) (see [Backend](#backend)),
with an in-memory mock mode for tests and offline UI work.

## Architecture

The app follows **MVC** (Model-View-Controller), extended with a
Repository/Service layer, as described in `doc/MVC_Architecture_in_Mobile_Application_Development_Guide.pdf`:

```
View (Flutter widgets)
  -> Controller (ChangeNotifier, via Provider)
    -> Repository (interface; API or mock implementation)
      -> Service (ApiClient: HTTP + token for the Laravel API,
                  or MockDataService: in-memory data)
```

- **Models** (`lib/models/`): plain data classes (`UserModel`, `ItemPostModel`,
  `ItemRequestModel`, `CategoryModel`, `RatingReviewModel`, `BadgeModel`).
  No logic, no I/O.
- **Views** (`lib/views/`): one subfolder per module (`auth`, `home`,
  `browse`, `give_away`, `requests`, `handover`, `profile`, `admin`,
  `settings`, `splash`). Widgets only — they read Controllers via
  `context.watch`/`context.read` and never talk to a repository directly.
- **Controllers** (`lib/controllers/`): `ChangeNotifier` classes that hold UI
  state, validate input, and call repositories. Registered once in
  `main.dart` via `MultiProvider` so any View can access them.
- **Repositories** (`lib/repositories/`): async mock CRUD methods with the
  same shape a real REST client would have (`Future<...>`, nullable
  results). Swapping `MockDataService` for an HTTP client later requires no
  changes above this layer.
- **Services** (`lib/services/`): `MockDataService` (single in-memory seed
  data store shared by all repositories) and `LocationService` (stub for a
  future geolocation API).
- **core/**: theme, app-wide constants (categories, Sri Lankan districts,
  badge thresholds), route name constants, and localization (ARB files +
  generated `AppLocalizations`).
- **widgets/**: small reusable UI pieces (`ItemCard`, `CategoryChip`,
  `BadgeIcon`, `RatingStars`, `CustomButton`, `EmptyState`,
  `LoadingIndicator`) shared across views.

## Features implemented

- Splash, Login, Register (single account acts as both Donor and Requester)
- Home with bottom navigation (Home / Profile / Settings) and Give
  Away / Requests tabs
- Category browsing (Educational Books, School Supplies, Clothes, Shoes,
  Electronics, Household Items, Other) and search/filter by category,
  district, and keyword
- Create Give Away post (photo picker, condition, category, district/city)
- Create Item Request (description + reason)
- Item details with "Request this item"
- Donor's incoming-requests review and requester selection
- Contact-details-shared screen, handover confirmation, and transaction
  completion
- Star rating & review after handover
- Profile (donation count, badge, ratings, my posts/requests), with Edit
  Profile
- Gamification badges: Bronze (5), Silver (10), Gold (25), Platinum (50+),
  with New / Active / Trusted Contributor / Community Champion levels
- Admin screens: manage users, moderate posts, manage categories
- Settings: language switch between English, Sinhala, and Tamil

## Project structure

```
lib/
├── main.dart                   # Provider wiring + named route table
├── core/
│   ├── theme/                  # Material 3 green theme
│   ├── constants/               # categories, districts, badge thresholds
│   ├── routes/                  # route name constants
│   └── localization/            # app_en.arb, app_si.arb, app_ta.arb (+ generated/)
├── models/
├── views/
│   ├── splash/ auth/ home/ browse/ give_away/ requests/ handover/
│   └── profile/ admin/ settings/
├── controllers/
├── repositories/
├── services/
└── widgets/
```

## Running the project

```bash
flutter pub get
flutter run
```

Run static analysis and tests:

```bash
flutter analyze
flutter test
```

## Backend

A PHP Laravel 13 REST API in [`backend/`](backend/README.md): accounts and
login tokens (Sanctum), posts with photos, requests, the handover workflow,
ratings, reports and admin moderation. See
[doc/BACKEND.md](doc/BACKEND.md) for the API, data model and rules.

Run both (Windows; PHP 8.3 and Flutter on PATH):

```bat
tool\start_backend.bat      :: first run installs, migrates and seeds; serves http://localhost:8000
tool\run_app_chrome.bat     :: flutter run -d chrome with API_BASE_URL=http://localhost:8000/api
tool\build_web_app.bat      :: or build once, then open http://localhost:8000/app
tool\check_all.bat          :: backend tests + flutter analyze + flutter test
```

or by hand:

```bash
cd backend && composer install && cp .env.example .env && php artisan key:generate
php artisan migrate --seed && php artisan serve
# in another terminal, from the repo root
cp .env.example .env
flutter run --dart-define-from-file=.env
```

Without `API_BASE_URL` the app runs on the in-memory mock data, which is
also what the Flutter tests use.
