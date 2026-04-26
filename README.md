# SafeDrive – UK Car Insurance App

A fully interactive Flutter application that allows UK drivers to get instant, realistic car insurance quotes, purchase policies, and submit claims — all backed by Supabase.

> **Academic Disclaimer:** SafeDrive is a university project built for illustrative and demonstration purposes. No real insurance is provided. All premiums are estimates only and do not constitute a binding offer of insurance.

---

## Table of Contents
1. [Features](#features)
2. [Screenshots Overview](#screenshots-overview)
3. [Tech Stack](#tech-stack)
4. [Project Structure](#project-structure)
5. [Getting Started](#getting-started)
6. [Environment Variables](#environment-variables)
7. [Supabase Setup](#supabase-setup)
8. [Pricing Model](#pricing-model)
9. [Architecture](#architecture)
10. [Contributing](#contributing)
11. [Licence](#licence)

---

## Features

| Feature | Description |
|---|---|
| 🔐 Auth | Email/password sign-up and sign-in via Supabase Auth |
| 🛡️ Onboarding | Animated 3-slide onboarding on first launch |
| 💬 Instant Quotes | UK-realistic premium calculation based on 10+ risk factors |
| 📋 Policy Purchase | Convert a saved quote into an active policy with one tap |
| 📂 My Policies | View, filter and cancel active/expired policies |
| 🚨 Claims | Submit new claims with incident details and track status progress |
| 👤 Profile | Account management, password reset, sign-out |
| 🗄️ Supabase Backend | PostgreSQL database with Row Level Security (RLS) |

---

## Screenshots Overview

| Screen | Description |
|---|---|
| Splash | Animated logo with trust-badge pills |
| Onboarding | 3 animated slides — skip or complete |
| Login / Sign Up | Tab-switched auth card with forgot-password dialog |
| Home (Dashboard) | Hero banner, quick-action cards, cover type cards, how-it-works steps |
| Personal Details | Full UK address form with live postcode lookup (postcodes.io) |
| Car Details | Cover type selector, 9 car categories, fuel/usage/NCD/excess pickers |
| Quote | Animated price hero card, itemised price breakdown, save and purchase |
| Policy Confirmation | Annual/monthly toggle, inclusions summary, activate policy |
| My Policies | Active / Past tabs with detailed policy cards |
| Policy Details | Full coverage view, cancellation, "Make a Claim" CTA |
| Claims | Submit claim form + status tracker with progress stepper |
| Profile | User avatar, settings menu, sign-out |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3.0+) |
| UI | Material 3, custom widgets |
| Backend | [Supabase](https://supabase.com) (Auth + PostgreSQL) |
| HTTP | `http` package (postcode lookup via postcodes.io) |
| State | `StatefulWidget` + `StreamBuilder<AuthState>` |
| Navigation | `Navigator` push/pop + `IndexedStack` bottom nav (4 tabs) |

---

## Project Structure

```
lib/
├── main.dart                            # App entry, AuthGate, SplashScreen routing
├── utils/
│   └── constants.dart                   # ALL brand colours, cover types, pricing data,
│                                        # table names — no magic strings elsewhere
└── screens/
    ├── splash_screen.dart               # 2.8s animated launch screen
    ├── onboarding_screen.dart           # 3-slide first-run walkthrough
    ├── login_screen.dart                # Sign In / Sign Up with Supabase Auth
    ├── home_screen.dart                 # Shell: Dashboard | Quotes | Policies | Profile
    ├── personal_details_screen.dart     # Step 1 of quote flow (with postcode API)
    ├── car_details_screen.dart          # Step 2 of quote flow
    ├── quote_screen.dart                # Price result + save + purchase
    ├── policy_confirmation_screen.dart  # Review & activate policy
    ├── my_policies_screen.dart          # Active / Past policy list
    ├── policy_details_screen.dart       # Full policy view + cancel + claim CTA
    └── claims_screen.dart               # Submit a claim + track claims

supabase/
└── schema.sql                           # Full PostgreSQL schema + RLS policies
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.0
- A [Supabase](https://supabase.com) project (free tier is sufficient)
- Dart 3.0+ (bundled with Flutter)

### 1 — Clone

```bash
git clone https://github.com/<your-username>/safedrive.git
cd safedrive
```

### 2 — Install dependencies

```bash
flutter pub get
```

### 3 — Configure Supabase credentials

Create a `.env` file in the project root (next to `pubspec.yaml`):

```
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

You can find both values in your Supabase dashboard under **Settings → API**.

The app reads these at startup via `flutter_dotenv`:

```dart
await dotenv.load(fileName: '.env');
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

> **Security note:** The `.env` file is already listed in `.gitignore`. Never commit real credentials to source control.

### 4 — Apply the database schema

1. Open your Supabase dashboard → **SQL Editor**
2. Paste the full contents of `supabase/schema.sql`
3. Click **Run**

This creates all five tables, enables RLS on each, creates the auth trigger, and registers the helper functions.

### 5 — Run

```bash
# Web (Chrome)
flutter config --enable-web
flutter run -d chrome

# Windows desktop
flutter config --enable-windows-desktop
flutter run -d windows

# Using VS Code
# Press F5 and select a configuration from .vscode/launch.json
```

---

## Environment Variables

Create a `.env` file in the project root. It is loaded at startup by `flutter_dotenv` and is excluded from git via `.gitignore`.

```
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL (Settings → API) |
| `SUPABASE_ANON_KEY` | Your Supabase public/anon key (Settings → API) |

---

## Supabase Setup

### Tables

| Table | Purpose |
|---|---|
| `user_profiles` | Extended user data (name, address, licence type) — auto-created on sign-up |
| `vehicles` | Reusable vehicle records linked to a user |
| `quotes` | Every price estimate generated by the app |
| `policies` | Purchased / active insurance policies |
| `claims` | Claims submitted against a policy |

### Row Level Security

All five tables have RLS enabled. Each policy restricts read and write access so that **users can only see and modify their own rows** (`auth.uid() = user_id`).

### Triggers and Functions

| Name | Behaviour |
|---|---|
| `handle_new_user()` | Auto-creates a `user_profiles` row whenever a new auth user is created |
| `handle_updated_at()` | Keeps `updated_at` accurate on every row update |
| `generate_policy_number()` | Returns a unique `SD-YYYY-XXXXXX` string |
| `generate_claim_number()` | Returns a unique `CLM-YYYY-XXXXXXX` string |

---

## Pricing Model

Premiums are calculated entirely client-side in `quote_screen.dart`. All data (base prices, multipliers, discount rates) is stored in `lib/utils/constants.dart`. All figures are illustrative only.

### Base Premiums

| Cover Type | Base Price |
|---|---|
| Third Party Only | £500 |
| TP Fire & Theft | £600 |
| Comprehensive | £720 |

### Risk Factors (applied sequentially)

| # | Factor | Range |
|---|---|---|
| 1 | Car category multiplier | City Car ×0.70 → Sports/Performance ×2.20 |
| 2 | Driver age band | Under-19 +£2,200; under-25 +£500; 70-74 +£200; 75+ +£400 |
| 3 | Car age | New (≤2 yrs) +£200; very old (>15 yrs) +£180 |
| 4 | Fuel type | Electric −£60; Hybrid −£30; Diesel +£45 |
| 5 | Usage type | Social & commuting +£120; Business use +£280 |
| 6 | Annual mileage | Under 5,000 −£70; over 20,000 +£250 |
| 7 | Licence type | Provisional +£380; International +£140; European +£80 |
| 8 | No Claims Discount | 1 yr 15% off → 5+ yrs 55% off |
| 9 | Voluntary excess | £500 saves 5%; £750 saves 10%; £1,000 saves 15% |

Final premium is clamped between **£150** and **£8,000**.
Monthly instalment = Annual ÷ 11.5 (small finance charge included).

---

## Architecture

```
main.dart
  └─ SplashScreen (2.8s) → AuthGate (StreamBuilder<AuthState>)
       ├─ session exists   → HomeScreen (4-tab IndexedStack)
       └─ no session       → OnboardingScreen → LoginScreen

HomeScreen tabs
  ├─ Tab 0  _DashboardTab     — hero banner, quick-action cards, cover info
  ├─ Tab 1  _MyQuotesTab      — Supabase quotes list, pull-to-refresh
  ├─ Tab 2  MyPoliciesScreen  — Active / Past tabs, policy cards
  └─ Tab 3  _ProfileTab       — user settings, sign-out

Quote Flow (Navigator push stack)
  PersonalDetailsScreen
    └─ CarDetailsScreen
         └─ QuoteScreen (save quote)
              └─ PolicyConfirmationScreen (activate policy)
                   └─ MyPoliciesScreen
                        └─ PolicyDetailsScreen
                             └─ ClaimsScreen (submit & track)
```

### Key Design Decisions

| Decision | Rationale |
|---|---|
| Declarative auth routing | `AuthGate` listens to `onAuthStateChange`; no manual `Navigator.push` after login |
| No hardcoded strings | Every constant lives in `lib/utils/constants.dart` |
| Public `switchTab()` method | Inner tab widgets call `shell?.switchTab(n)` instead of accessing protected `setState` directly |
| RLS on every table | Flutter app only holds the anon key; the database enforces user isolation |
| `IndexedStack` for tabs | Keeps each tab's state alive when switching — avoids re-fetching on tab switch |

---

## Contributing

1. Fork the repository and create a feature branch: `git checkout -b feature/your-feature`
2. Follow the existing code style — use `AppColors.*` and `constants.dart` classes, no raw colour hex values
3. Test on at least one platform (`flutter run -d chrome` or `-d windows`)
4. Open a pull request with a clear title and description

---

## Licence

This project is submitted as part of a university module at Edinburgh Napier University and is provided for educational use only. All insurance figures and product descriptions are for demonstration purposes and do not constitute real financial advice or insurance cover.
