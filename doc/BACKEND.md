# ShareLoop backend

A PHP **Laravel 13** REST API in [`backend/`](../backend/README.md). It
handles everything: accounts and sign-in, posts and photos, requests, the
handover workflow, ratings, reports and admin moderation. (It replaces the
earlier Firebase Auth + Supabase setup.)

```
Flutter app ── HTTPS/JSON ──▶ Laravel API (/api) ──▶ SQLite (dev) / MySQL (prod)
   │  Authorization: Bearer <Sanctum token>            └─▶ storage/app/private/item-images
   └─ token kept with shared_preferences until logout
```

When `API_BASE_URL` is not defined at build time the app runs on the
in-memory `MockDataService` instead (tests, offline UI work). Each
repository picks its implementation in a factory constructor, so
controllers and views are the same in both modes.

## 1. Layers

| Layer | Real backend | Mock |
|---|---|---|
| `lib/repositories/*_repository.dart` | interface + factory | |
| `lib/repositories/api/` | HTTP calls + JSON mapping (`api_rows.dart`) | |
| `lib/repositories/mock/` | | `MockDataService` |
| `lib/services/api_client.dart` | base URL, bearer token, errors → `AppException` | not used |
| `lib/core/config/backend_config.dart` | `API_BASE_URL`, limits | |
| `backend/app/Http/Controllers/Api` | endpoints | |
| `backend/app/Services/ExchangeService.php` | handover workflow, in transactions | |

## 2. API

All routes are under `/api`, JSON in and out. Errors are
`{"message": "...", "errors": {field: [..]}}` (`errors` only for 422); the
messages are written for users and the app shows them as they are.

| Method & path | Who | Does |
|---|---|---|
| `POST /auth/register` | anyone | `{name, email, password, phone, district, city}` → `{token, user}` |
| `POST /auth/login` | anyone | `{email, password}` → `{token, user}`; 401 wrong password, 403 suspended |
| `POST /auth/forgot-password` | anyone | emails a reset link (same answer whether or not the account exists) |
| `GET /auth/me`, `POST /auth/logout` | signed in | current user; revoke this token |
| `PATCH /me` | signed in | edit own `name, phone, district, city` |
| `GET /categories` | anyone | active categories |
| `GET /users`, `GET /users/{id}` | signed in | profiles; `email`/`phone` are `null` unless you may see them |
| `GET /users/{id}/ratings` | signed in | ratings received |
| `GET /items?limit=&offset=&category=&district=&q=` | signed in | feed, newest first, hidden posts excluded |
| `GET /items?donor_id=` | signed in | one donor's posts (their own hidden ones included for them) |
| `GET /items/{id}` | signed in | one post (hidden: donor and admins only) |
| `POST /items` (multipart) | signed in | `title, description, condition, category, district, city, photos[]` (≤5 JPEG/PNG/WebP, ≤5 MB each) |
| `DELETE /items/{id}` | donor (not during a handover) or admin | deletes post, its requests and photos |
| `GET /requests?item_id=&requester_id=` | signed in | requests you may see |
| `POST /requests` | signed in | a need (`item_name`) or a request for a post (`item_id`) |
| `DELETE /requests/{id}` | requester (unless approved) or admin | |
| `POST /requests/{id}/select` | the post's donor | approve this request, start the handover |
| `GET /items/{id}/exchange` | the two parties, admins | live exchange or `{"data": null}` |
| `POST /items/{id}/confirm-handover` | either party | records your confirmation; completes when both have |
| `POST /items/{id}/cancel-exchange` | either party, before completion | post back on offer |
| `POST /items/{id}/ratings` | a party who confirmed | `{stars 1-5, comment}`; ratee worked out by the server |
| `GET /reports`, `POST /reports` | signed in | own reports; report one item, request or user |
| `GET /admin/users?status=`, `PATCH /admin/users/{id}/status` | admins | list; suspend/restore (suspending revokes tokens) |
| `GET /admin/items?hidden=`, `PATCH /admin/items/{id}/hidden` | admins | moderate posts (reversible) |
| `PATCH /admin/requests/{id}/hidden` | admins | moderate needs |
| `PATCH /admin/reports/{id}` | admins | resolve as `actioned` / `dismissed` |
| `POST /admin/categories`, `DELETE /admin/categories/{id}` | admins | add; retire (existing posts keep it) |
| `GET /photos/{path}?expires=&signature=` | link holders | photo, via signed URLs that expire after 1 hour |
| `GET /health` | anyone | `{"status": "ok"}` |

## 3. Data model

Migrations: `backend/database/migrations/`.

| Table | Purpose |
|---|---|
| `users` | account + public profile: name, email, password hash, phone, district, city, donation count, rating summary, `is_admin`, `status` (`active`/`suspended`) |
| `personal_access_tokens` | Sanctum API tokens (30 days; `SHARELOOP_TOKEN_DAYS`) |
| `categories` | the app's 7 categories (seeded); admins add/retire |
| `items` | give-away posts; `image_paths`; `status` `active → pending_handover → completed`; `is_hidden` |
| `item_requests` | needs (`item_id` null) or requests for a post; `pending / approved / rejected`; one per requester per post |
| `exchanges` | donor ↔ selected requester; `donor_confirmed_at`, `requester_confirmed_at`; kept with a title snapshot if the post is deleted |
| `ratings` | 1–5 stars, one per party per exchange; keeps `users.rating_avg/rating_count` current |
| `reports` | user reports for admins; `open / actioned / dismissed` |

## 4. Rules (enforced by the API, not just the app)

- Only active accounts can use the API. Suspending an account revokes its
  tokens at once; old tokens get 403.
- Contact details (email, phone) are visible to the user, admins, and the
  other party of a live (not cancelled) exchange — so they are shared only
  after the donor selects a requester.
- Requests for a specific post are visible only to the requester and that
  post's donor; needs are visible to every signed-in user.
- You can't request your own post, a hidden one, or one that's no longer
  active, and only once per post.
- Only the donor selects a requester, only while the post is active and
  the request pending. One live exchange per post.
- Confirming twice is harmless. When both parties have confirmed, the
  exchange and post complete, the donor's donation count goes up, and the
  other pending requests are rejected.
- Cancelling puts the post back on offer, rejects the selected request and
  removes ratings for that exchange.
- Rating needs your own confirmation first; the server picks the ratee.
- A post can't be deleted during a handover (admins can); an approved
  request can't be deleted.
- Every multi-row change runs in one database transaction with the rows
  locked (`ExchangeService`).

## 5. Photos

Stored on Laravel's private `local` disk (`storage/app/private/item-images/<user id>/<random>.jpg|png|webp`),
validated as real images, max 5 per post and 5 MB each. The API returns
`image_urls`: signed links to `/api/photos/...` valid for one hour, so
`Image.network` works without sending the token. Deleting a post deletes
its photos; a failed post removes photos it already stored.

## 6. Configuration

App (`.env` at the repo root, compiled into the app — public values only):

| Name | Example |
|---|---|
| `API_BASE_URL` | `http://localhost:8000/api` (Chrome/Windows), `http://10.0.2.2:8000/api` (Android emulator) |

Backend (`backend/.env`, never committed):

| Name | Purpose |
|---|---|
| `APP_KEY` | generated by `php artisan key:generate` |
| `APP_URL` | public URL of the API (used in reset-password links) |
| `DB_CONNECTION` | `sqlite` (default, `database/database.sqlite`) or `mysql` with `DB_HOST/PORT/DATABASE/USERNAME/PASSWORD` |
| `MAIL_*` | how reset emails are sent; `MAIL_MAILER=log` writes them to `storage/logs/laravel.log` |
| `SHARELOOP_ADMIN_EMAIL`, `SHARELOOP_ADMIN_PASSWORD` | seeded admin account (optional) |
| `SHARELOOP_TOKEN_DAYS` | API token lifetime (default 30) |

## 7. Running and testing

See [`backend/README.md`](../backend/README.md). In short (Windows, from
the repo root):

| Script | Does |
|---|---|
| `tool\start_backend.bat` | installs, migrates, seeds demo data, serves the API on port 8000 (`lan` argument: reachable from phones on your Wi-Fi) |
| `tool\stop_backend.bat` | stops it |
| `tool\run_app_chrome.bat` | `flutter run -d chrome` against the API |
| `tool\run_app_web.bat` | debug web build at http://localhost:5000 for any browser |
| `tool\build_web_app.bat` | release web build served by the API itself at http://localhost:8000/app (one address, handy for demos) |
| `tool\check_all.bat` | backend tests + `flutter analyze` + `flutter test` |

| Check | How |
|---|---|
| Backend feature tests | `cd backend && php artisan test` (41 tests: auth, visibility, every workflow rule, photos, admin) |
| Flutter analysis/tests | `flutter analyze`, `flutter test` (mock data + `test/api_repositories_test.dart` with a fake API) |
| Manual | demo accounts from `DemoSeeder` (password `password`) |

Make someone an admin: `php artisan shareloop:make-admin someone@example.com`.

## 8. Known limitations

- Feeds load the newest 50 posts / 200 requests and filter on the device;
  the API already supports `category`, `district` and `q` filters for
  server-side search later.
- Admin-added categories are stored but the pickers still use
  `AppConstants.itemCategories`.
- No "Report" button in the app yet (the API is ready).
- No avatar upload yet.
- Reset emails go to the log until real mail settings are added.
- Phone OTP sign-in (e.g. via httpSMS) isn't built yet; accounts use email
  and password.
