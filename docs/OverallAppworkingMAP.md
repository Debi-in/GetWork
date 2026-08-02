Frontend:
Flutter

Backend:
Supabase

Database:
PostgreSQL

Maps:
MapTiler + flutter_map

MapTier Claud Key = "DjzvVwLyrsp0aDuDoccX"

Routing:
GraphHopper or OSRM

State Management:
Riverpod

Navigation:
GoRouter

Notifications:
Firebase Cloud Messaging

Analytics:
Firebase Analytics

Crash Reports:
Firebase Crashlytics

Hosting:
Vercel

Repository:
GitHub



Install Packages

Run these commands:

flutter pub add flutter_map
flutter pub add latlong2
flutter pub add geolocator
flutter pub add permission_handler
flutter pub add flutter_riverpod
flutter pub add go_router
flutter pub add supabase_flutter
Connect GitHub
git init
git add .
git commit -m "Initial LocalWork project"

Create a GitHub repository named:

localwork-app

Then:

git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/localwork-app.git
git push -u origin main
Create a .env File

Don't put your API key directly in your code.

Instead, later we'll store it like this:

MAPTILER_API_KEY=YOUR_MAPTILER_KEY
SUPABASE_URL=YOUR_SUPABASE_URL
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

For Flutter, we'll likely use flutter_dotenv or --dart-define so secrets aren't hardcoded into the app.

Your Development Order
✅ GitHub
✅ MapTiler
⏳ Flutter project
⏳ Supabase
⏳ Firebase
⏳ Interactive map
⏳ Custom salary markers
⏳ Bottom sheet
⏳ Job posting
⏳ Authentication



