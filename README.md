# ShareLoop

A Flutter front-end for **ShareLoop** — a recycling & item-sharing platform for
Sri Lanka ("Give What You Don't Need. Get What You Do."). This is the UI
layer only: all data is mocked in-memory, ready to be swapped for a real
REST API later without touching any View or Controller code.

## Architecture

The app follows **MVC** (Model-View-Controller), extended with a
Repository/Service layer, as described in `doc/MVC_Architecture_in_Mobile_Application_Development_Guide.pdf`:

```
View (Flutter widgets)
  -> Controller (ChangeNotifier, via Provider)
    -> Repository (mock CRUD, async)
      -> Service (MockDataService: in-memory hard-coded data)
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

## Notes for backend integration

- Replace the body of `MockDataService` with real HTTP calls (or inject a
  different implementation) — repositories already use `Future<...>`
  signatures that match a typical REST client.
- `AuthController.login`/`register` and `UserRepository` are the natural
  seam for wiring real authentication.
- `image_picker` results are currently stored as local file paths only
  (`ItemPostModel.photoPaths`); a real backend would upload these and store
  returned URLs instead.
