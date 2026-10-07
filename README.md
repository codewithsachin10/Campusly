# Campusly 🎓

**Campusly** is a production-grade academic companion and smart timetable application built for students and faculty. Engineered with Flutter, Riverpod 3, GoRouter, and Supabase backend services, it delivers real-time schedules, attendance intelligence, exam venue navigation, urgent campus alerts, and event promotions.

---

## 🌟 Key Features

- **Smart Dynamic Timetable:** Real-time timetable view that highlights ongoing classes, counts down to upcoming periods, and adapts to day schedules automatically.
- **Class Joining & Custom Timetables:** Join section timetables by code or create personalized custom timetables.
- **Attendance Tracker & Forecaster:** Visual percentage gauges, safe bunk calculators, and target attendance goals.
- **Exam Timetables & Venues:** Complete exam date schedules and classroom/block venue mapping.
- **Urgent Alerts & Notifications:** Instant class cancellation notices, room change alerts, and push updates.
- **Events & Promotional Banners:** Interactive event banners, hackathon announcements, and external links.
- **Campus Directory & Faculty Profiles:** Search faculty cabin locations, contact emails, and office hours.
- **Support & Help Desk:** In-app ticket submission and resolution tracking.
- **Web Admin Portal (`campusly_web_admin`):** Web management suite for timetables, exam schedules, banner campaigns, and app releases.

---

## 🏗️ Project Architecture

Campusly follows a clean **Feature-First Architecture**:

```
lib/
├── core/                        # Shared infrastructure
│   ├── router/                  # GoRouter navigation & route guards
│   ├── theme/                   # AppTheme, AppColors, typography tokens
│   ├── services/                # Storage, notifications, error handlers
│   └── widgets/                 # Reusable UI components
├── features/                    # Feature modules (Domain, Data, Presentation)
│   ├── auth/                    # Google & Supabase authentication
│   ├── campus/                  # Campus buildings, maps, locations
│   ├── class_join/              # Section onboarding & code joining
│   ├── curriculum/              # Academic curriculum & subjects
│   ├── events/                  # Campus events & promo banners
│   ├── notifications/           # Push alerts & class change dialogs
│   ├── profile/                 # Student profile & academic details
│   ├── support/                 # Help desk & ticket management
│   └── timetable/               # Timetable view, exam schedules, attendance
└── main.dart                    # Application entry point & service bootstrap
```

Accompanying sub-projects:
- **`campusly_web_admin/`**: TanStack/Vite React admin dashboard.
- **`supabase/`**: Database migrations, RLS policies, and Deno edge functions.
- **`tools/`**: Deployment and administrative maintenance scripts.

---

## 🚀 Getting Started (Mobile App)

### Prerequisites
- Flutter SDK `3.22.0` or higher
- Dart `3.4.0` or higher
- Android SDK 34 / iOS 15+

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/codewithsachin10/Campusly.git
   cd Campusly
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run the App with Environment Variables (`--dart-define`):**
   Supabase credentials are not hardcoded. Pass your credentials using `--dart-define`:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<your-project-id>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<your-supabase-anon-key>
   ```

4. **Build Release APK:**
   ```bash
   flutter build apk --release \
     --dart-define=SUPABASE_URL=https://<your-project-id>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<your-supabase-anon-key>
   ```

---

## 🖥️ Web Admin Setup (`campusly_web_admin`)

1. **Navigate to the web admin directory:**
   ```bash
   cd campusly_web_admin
   npm install
   ```

2. **Configure `.env`:**
   Create a `.env` file inside `campusly_web_admin/` (never commit this file):
   ```env
   VITE_SUPABASE_URL=https://<your-project-id>.supabase.co
   VITE_SUPABASE_ANON_KEY=<your-supabase-anon-key>
   SUPABASE_SERVICE_ROLE_KEY=<your-supabase-service-role-key>
   ```

3. **Start Development Server:**
   ```bash
   npm run dev
   ```

---

## 🔐 Security & Best Practices

- **Never Commit Secrets:** `service_role` keys, API tokens, and `.env` files are ignored in `.gitignore`.
- **Environment Driven:** Both the Flutter client (`--dart-define`) and the Admin Dashboard (`process.env`) read configuration at build/run time.
- **Row Level Security (RLS):** All public-facing Supabase tables enforce RLS policies so students only read authorized data and cannot modify admin resources.
