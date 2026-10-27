# ShareLoop backend

Firebase Authentication signs users in. Supabase (Postgres + Storage) holds
all app data and accepts the user's Firebase ID token directly. There is no
custom server.

```
Flutter app ──signIn──▶ Firebase Auth ──ID token (JWT, 1 h, auto-refreshed)──┐
     │                                                                       │
     └── every Supabase request carries that token ─────────────────────────▶ Supabase
                                                          verifies signature (Firebase third-party auth)
                                                          RLS: requesting_user_id() = token.sub
                                                               only if iss/aud = shareloop-c2157
```

When `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` are not defined at build
time, the app runs on the in-memory `MockDataService` instead (tests, offline
UI work). Each repository picks its implementation in a factory constructor,
so controllers and views are the same in both modes.

## 1. Architecture

| Layer | Real backend | Mock |
|---|---|---|
| `lib/repositories/*_repository.dart` | interface + factory | |
| `lib/repositories/supabase/` | Firebase Auth + Supabase | |
| `lib/repositories/mock/` | | `MockDataService` |
| `lib/services/backend_service.dart` | starts Firebase + Supabase, maps errors to `AppException` | not used |
| `lib/core/config/backend_config.dart` | build-time public config, limits | |

Multi-row state changes (selecting a requester, confirming a handover,
rating, moderation) run inside Postgres functions, so the rules hold no
matter what client calls the API. Clients only get column-level `UPDATE`
grants for plain edits.

## 2. Database schema

Migrations: `supabase/migrations/` (apply in filename order; never edit one
that has been applied to a real project, add a new one instead).

| Table | Purpose | Who can read |
|---|---|---|
| `profiles` | public profile: name, district, city, donation count, rating summary, `is_admin`, `status` (`active`/`suspended`). `id` = Firebase UID (text). | any signed-in user |
| `profile_contacts` | email (from the verified token) and phone | the user, admins, and the other party of a live exchange |
| `categories` | reference data (seeded with the app's 7 categories) | everyone; admins write |
| `items` | give-away posts; `image_paths` in the user's storage folder; `status` `active → pending_handover → completed`; `is_hidden` for moderation | signed-in users (hidden: donor + admins only) |
| `item_requests` | standalone needs (`item_id` null) or requests for an item; `status` `pending / approved / rejected`; one per requester per item | needs: all signed-in users; item requests: requester, item donor, admins |
| `exchanges` | donor ↔ selected requester; `donor_confirmed_at`, `requester_confirmed_at`; completes only when both are set | the two parties, admins |
| `ratings` | 1–5 stars after a confirmed handover, one per party per exchange; trigger keeps `profiles.rating_avg/rating_count` current | signed-in users |
| `reports` | user reports on an item, request or user; `open / actioned / dismissed` | reporter, admins |

Key constraints: Sri Lankan districts are a domain; item photos must live
under `<donor uid>/`; a user can't request their own item or one that isn't
active; at most one live exchange per item; a completed exchange must have
both confirmations.

### Workflow functions (RPC)

| Function | Caller | Effect |
|---|---|---|
| `create_my_profile(name, district, city, phone)` | new user | creates profile + contacts atomically; email taken from the token |
| `select_requester(request_id)` | item donor | request → approved, item → pending_handover, exchange created (contacts now shared) |
| `confirm_handover(item_id)` | either party | records that party's confirmation; when both have: exchange + item completed, donor's `donation_count` +1, other pending requests rejected |
| `cancel_exchange(item_id)` | either party, before completion | item back to active, selected request rejected, ratings for it removed |
| `submit_rating(item_id, stars, comment)` | a party who has confirmed | ratee derived server-side |
| `admin_set_user_status`, `admin_set_item_hidden`, `admin_set_request_hidden`, `admin_resolve_report` | admins | moderation (reversible) |

## 3. Authentication and authorization

- Register: Firebase `createUserWithEmailAndPassword` → `create_my_profile`.
  If the profile step fails, the new Firebase account is deleted again. If a
  previous attempt left a Firebase account without a profile, registering
  again with the same password finishes it.
- Login: Firebase sign-in → load profile. Suspended or profile-less accounts
  are signed out with a message.
- Session: Firebase persists it; on launch `getCurrentUser()` reloads the
  Firebase user (fails for disabled/deleted accounts → signed out) and the
  splash goes to Home when a session is restored.
- Password reset: Firebase reset email to the address typed on the login
  screen.
- Supabase receives the token through `Supabase.initialize(accessToken: …)`.
  Supabase verifies the signature against Firebase's keys. Because Firebase
  signs tokens for every Firebase project with the same keys, every policy
  uses `public.requesting_user_id()`, which returns the UID only when
  `iss`/`aud` match `shareloop-c2157`.
- No `role: authenticated` custom claim is set (that needs Cloud Functions,
  i.e. the paid Blaze plan), so Firebase tokens run as the Postgres `anon`
  role. Grants therefore cover `anon` and `authenticated` alike and RLS does
  the real checks; a request with no token has `requesting_user_id() = null`
  and every write is refused.
- Never use `auth.uid()` in SQL: it casts to `uuid` and Firebase UIDs are not
  UUIDs.
- Disabled/deleted Firebase users: Supabase cannot see revocation, so an
  already-issued token keeps working until it expires (≤ 1 hour). Use
  `admin_set_user_status(..., 'suspended')` to cut access immediately.

## 4. Storage

Bucket `item-images` (private, 5 MB per file, JPEG/PNG/WebP). Objects are
`<firebase uid>/<random hex>.<ext>`.

- Upload/replace: only into your own folder, only while not suspended.
- Read: any signed-in user, through signed URLs valid for 1 hour (created in
  one batch per page of posts).
- Delete: the owner or an admin. Deleting a post deletes its photos.
- Photos are uploaded before the post is inserted; if the insert fails the
  uploads are removed.

Private rather than public because listings are only shown to signed-in
users, and household photos shouldn't be readable by anyone with a link.
Trade-off: signed URLs change on each load, so images are not cached across
refreshes.

## 5. Environment variables

`.env` (copy of `.env.example`, git-ignored), passed with
`--dart-define-from-file=.env`. Everything in it is compiled into the app,
so it holds public values only:

| Name | Where to find it |
|---|---|
| `SUPABASE_URL` | Dashboard → Project Settings → API |
| `SUPABASE_PUBLISHABLE_KEY` | Dashboard → Project Settings → API Keys (publishable, or legacy anon) |

Server-only values, which never go in `.env` or in the app: the database
password (only typed into `supabase link`/`db push` prompts), the
service-role / secret key (not used by ShareLoop at all), Firebase Admin
credentials (not used).

Firebase client config lives in `lib/firebase_options.dart` (generated by
FlutterFire). Its API keys identify the project and are not secrets, but
restrict them to the app's package names in Google Cloud Console.

## 6. Setup and deployment

```bash
# Supabase CLI runs through npx (no install needed)
npx supabase login                                   # opens the browser
npx supabase link --project-ref <ref>                # asks for the DB password
npx supabase db push --dry-run                       # review
npx supabase db push                                 # apply migrations

# Firebase client config (registers/uses the apps in shareloop-c2157)
dart pub global activate flutterfire_cli
flutterfire configure --project=shareloop-c2157 --platforms=android,ios,web

# Run against the real backend
flutter run --dart-define-from-file=.env
```

## 7. Manual dashboard actions

1. **Supabase:** create the project (Free plan; region nearest Sri Lanka,
   e.g. South Asia (Mumbai)). Keep the database password in a password
   manager.
2. **Supabase → Authentication → Third-party Auth:** add Firebase with
   project ID `shareloop-c2157`. (Alternatively `npx supabase config diff`,
   then `npx supabase config push`. Review the diff first: `config.toml`
   also contains local-development defaults such as `site_url`.)
3. **Firebase → Authentication → Sign-in method:** enable Email/Password.
4. **First admin:** after registering, in the Supabase SQL editor:
   `update public.profiles set is_admin = true where id = '<firebase uid>';`

## 8. Testing

| Check | How | Notes |
|---|---|---|
| Static analysis | `flutter analyze` | |
| Widget/unit tests | `flutter test` | run on mock data; `test/exchange_flow_test.dart` covers the exchange rules |
| Migrations + RLS | `cd tool/db_check && npm install && npm test` | applies the migrations to PGlite (Postgres 17 in WASM) with stubs for Supabase's `auth` and `storage` schemas, then checks ~90 access and workflow rules as different Firebase users. Does not exercise real Supabase services (PostgREST, Storage API, token verification). |
| Real project (read-only) | `cd tool/db_check && npm run remote-check` | uses `.env`; never prints the key, refuses secret/service-role keys, never writes. Checks the key, whether migrations are applied, that no rows are visible without a user token, and that forged tokens are rejected. With `SHARELOOP_TEST_EMAIL`/`SHARELOOP_TEST_PASSWORD` set in your shell (and FlutterFire configured) it also checks that Supabase accepts a real Firebase ID token and that contact details stay isolated. |
| End-to-end | manual, with a configured project | not automated yet |

## 9. Known limitations

- Feeds load the newest 50 posts / 200 requests and filter on the device;
  server-side filtering and infinite scroll are not wired up yet (indexes,
  including trigram search, are in place).
- Admin-added categories are stored in the database but the pickers still
  use `AppConstants.itemCategories`.
- The `reports` table and admin RPCs exist, but the app has no "Report"
  button or reports screen yet.
- `avatar_path` exists but there is no avatar upload yet.
- Photos of hidden posts remain readable by signed-in users who have the
  path.
- Phone numbers are visible to both parties for the life of a completed
  exchange.
- Server error messages from SQL functions are English only.

## 10. Free Plan usage

Supabase Free (checked October 2026): 500 MB database, 1 GB file storage,
5 GB egress + 5 GB cached egress, 50,000 MAU (third-party MAU included),
2 active projects, **paused after 1 week of inactivity**, no automatic
backups, no image transformations.

Rough estimate for ShareLoop: a post row is ~1 KB, so the database holds
hundreds of thousands of posts. Storage is the real limit. At 3 photos of
~300 KB each (1600 px, JPEG 85), 1 GB fits about 1,100 posts with photos.
Egress follows from browsing: each feed load of 50 posts with covers is
~15 MB, so 5 GB is about 330 such loads a month. Plan for Supabase Pro, or
smaller thumbnails, before a public launch.

Firebase Spark: email/password auth is free up to 50,000 MAU. Email
verification and password-reset emails are subject to Firebase's sending
quotas.
