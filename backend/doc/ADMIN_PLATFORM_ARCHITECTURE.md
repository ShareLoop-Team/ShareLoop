# ShareLoop Admin Operations & Intelligence Platform (Architecture & Specification)

## 1. Executive Summary & Design Aesthetics

The **ShareLoop Web Admin Operations & Intelligence Platform** is a web-based control center built directly into the Laravel application, connecting to RESTful endpoints with security, auditability, and analytics.

- **URL Endpoint**: `/admin`
- **UI Architecture**: Single Page Application (SPA) with Material 3 SaaS design principles
- **Color Palette**:
  - Primary: `#2E7D32` (Forest Green)
  - Secondary: `#4CAF50` (Vibrant Emerald)
  - Accent: `#81C784` (Soft Leaf)
  - Dark Surface: `#0B110D` (Deep Charcoal Base), `#111A13` (Surface), `#18241C` (Elevated)
  - Light Surface: `#F3F7F4` (Base), `#FFFFFF` (Card), `#EBF2EC` (Subtle)
- **Visual Features**: Real-time KPI cards, dynamic Chart.js visualizations, responsive tables, audit diff viewers, dark/light theme toggle, and modal drawers.

---

## 2. All 17 Core Modules

| # | Module | Core Capabilities |
|---|---|---|
| **1** | **Dashboard Overview** | Total Users, Active Users, New Users Today, Total Donations, Completed Handovers, Pending Requests, Category Counts, Reviews Count, Real-Time Health Status (99.98%), Top Donors, Most Requested Categories. |
| **2** | **User Management** | Search, district & status filters, detailed profile inspection (donations history, received items, reviews, badges, account status). Actions: Activate, Suspend, Ban with reason, Reset Password, Force Logout, Verify Account, Delete Account. |
| **3** | **Item Management** | Filter by category, district, condition, moderation status (`approved`, `pending`, `rejected`, `archived`), and AI flags. Actions: Approve, Reject, Archive, Hide/Unhide with reason, Trigger AI Moderation Scan, Delete Listing. |
| **4** | **Request Management** | Queue of community item requests, need/reason inspection, donor-requester matching. Actions: Approve, Reject, Cancel, Escalate, Toggle Hide. |
| **5** | **Moderation Center** | Reported content queue (items, users, comments). Resolution workflow: Dismiss report, Remove violating content, Suspend user, Ban user. Integrated AI scoring for scam, spam, and toxicity. |
| **6** | **Category Management** | Full CRUD for item categories (Books, School Supplies, Clothes, Electronics, Household Items, etc.), icon names, sort order, and item count safety validation before deletion. |
| **7** | **Reviews & Ratings** | Ratings list, 5-star to 1-star distribution breakdown, average community rating, and action to remove/hide toxic reviews while automatically refreshing the user's score summary. |
| **8** | **Gamification System** | Karma points, trust scores (0-100%), badge tiers (**Bronze**, **Silver**, **Gold**, **Platinum**). Actions: Award badges, adjust points, and recalibrate trust scores. |
| **9** | **Location Management** | Sri Lanka 25 districts distribution analysis, donation density vs request density, top active cities, and district activity heatmaps. |
| **10** | **Analytics & Reports** | 14-to-30 day donation and user growth velocity, monthly completed transaction volume, donor retention & conversion rates, and CSV streamed exports for Users, Items, and Handovers. |
| **11** | **Security Center** | 24-hour failed login telemetry, multi-device active sessions detector, suspicious accounts radar, and IP Blacklist CRUD with auto-expiration. |
| **12** | **Audit Logs** | Immutable system audit trail capturing `timestamp`, `user_id`, `action`, `entity_type`, `entity_id`, before/after JSON diffs (`old_values` vs `new_values`), `ip_address`, and `user_agent`. |
| **13** | **System Settings** | Platform configuration editor: Global Platform Name, Support Contact Email, Max Concurrent Requests per User, Maintenance Mode toggle, and Notification settings. |
| **14** | **Database Inspector** | Safe read-only inspection of database tables (`users`, `items`, `item_requests`, `exchanges`, `categories`, `audit_logs`, `system_settings`), column schemas, search by column, and paginated records. |
| **15** | **API Monitoring** | Live API telemetry: 24h request counter, average latency (ms), error rate % (4xx/5xx), HTTP method distribution (GET, POST, PUT, PATCH, DELETE), and top endpoint performance stats. |
| **16** | **Notification Center** | Broadcast announcements across **In-App**, **Push Notifications (FCM)**, and **Email** to **All Users**, **Active Donors**, **Requesters**, or **Specific User IDs**. |
| **17** | **Super Admin Panel** | Administrative governance: Admin users list, Role assignments, and granular Role Permission Matrix across 15+ permission groups. |

---

## 3. Database Schema Extensions

### `admin_roles`
- `id` (UUID, Primary Key)
- `name` (String: Super Administrator, Community Moderator, Support Staff, Content Reviewer)
- `slug` (String, Unique)
- `description` (String, Nullable)
- `is_system` (Boolean)
- `timestamps`

### `admin_permissions`
- `id` (UUID, Primary Key)
- `name` (String)
- `slug` (String, Unique)
- `group` (String: Users, Items, Moderation, Settings, etc.)
- `timestamps`

### `admin_role_permission`
- `role_id` (Foreign UUID -> admin_roles)
- `permission_id` (Foreign UUID -> admin_permissions)
- Primary Key: `(role_id, permission_id)`

### `users` (New Admin Columns)
- `role_id` (Foreign UUID -> admin_roles, Nullable)
- `is_banned` (Boolean, Default: false)
- `banned_at` (Timestamp, Nullable)
- `ban_reason` (String, Nullable)
- `is_verified` (Boolean, Default: false)
- `points` (Integer, Default: 0)
- `badge` (String: Bronze, Silver, Gold, Platinum)
- `trust_score` (Integer, Default: 100)
- `last_login_at` (Timestamp, Nullable)
- `last_login_ip` (String, Nullable)

### `items` (New Moderation Columns)
- `moderation_status` (String: approved, pending, rejected, archived)
- `moderation_notes` (Text, Nullable)
- `moderated_by` (Foreign UUID -> users, Nullable)
- `moderated_at` (Timestamp, Nullable)
- `ai_toxicity_score` (Integer: 0-100)
- `ai_scam_score` (Integer: 0-100)
- `ai_flagged` (Boolean, Default: false)

### `audit_logs`
- `id` (UUID, Primary Key)
- `user_id` (Foreign UUID -> users, Nullable)
- `action` (String)
- `entity_type` (String, Nullable)
- `entity_id` (String, Nullable)
- `old_values` (JSON, Nullable)
- `new_values` (JSON, Nullable)
- `ip_address` (String, Nullable)
- `user_agent` (Text, Nullable)
- `description` (Text, Nullable)
- `timestamps`

### `security_logs`
- `id` (UUID, Primary Key)
- `user_id` (Foreign UUID -> users, Nullable)
- `event_type` (String)
- `severity` (String: info, warning, critical)
- `ip_address` (String, Nullable)
- `user_agent` (Text, Nullable)
- `details` (JSON, Nullable)
- `timestamps`

### `blacklisted_ips`
- `id` (UUID, Primary Key)
- `ip_address` (String, Unique)
- `reason` (String, Nullable)
- `blocked_by` (Foreign UUID -> users, Nullable)
- `blocked_until` (Timestamp, Nullable)
- `timestamps`

### `system_settings`
- `key` (String, Primary Key)
- `value` (LongText, Nullable)
- `type` (String: string, boolean, integer, json)
- `group` (String: general, email, notifications, security, localization)
- `description` (String, Nullable)
- `updated_by` (Foreign UUID -> users, Nullable)
- `timestamps`

### `admin_notifications`
- `id` (UUID, Primary Key)
- `title` (String)
- `message` (Text)
- `target_type` (String: all, donors, requesters, specific)
- `target_user_ids` (JSON, Nullable)
- `channel` (String: in_app, email, push, all)
- `sent_by` (Foreign UUID -> users, Nullable)
- `recipients_count` (Integer)
- `timestamps`

### `api_metrics`
- `id` (UUID, Primary Key)
- `method` (String: GET, POST, PUT, PATCH, DELETE)
- `endpoint` (String)
- `status_code` (Integer)
- `response_time_ms` (Float)
- `ip_address` (String, Nullable)
- `timestamps`

---

## 4. Key Security & Defense In Depth

1. **IP Blacklist Gatekeeper (`CheckIpBlacklist` Middleware)**: Automatically blocks blacklisted IP addresses across all API and web requests with instant `403 Forbidden` response.
2. **API Telemetry & Rate Auditing (`RecordApiMetrics` Middleware)**: Asynchronously samples API latency, methods, and status codes to provide real-time endpoint health.
3. **Audit Logging (`AuditLogger` Service)**: Automatically logs mutations with actor IP, User-Agent, and full before/after JSON diffs.
4. **AI Moderation Engine (`AiModerationService`)**: Inspects listings for toxic terms, fraudulent advance-fee requests, Western Union/wire requests, and scam patterns.
5. **Token Revocation (`SecurityService::forceLogout`)**: Immediately invalidates all Sanctum personal access tokens for suspended or banned accounts across all devices.
