One App, Two Roles
LocalWork
        │
        ▼
Authentication
        │
        ▼
User chooses role
        │
        ├───────────────┐
        ▼               ▼
Worker          Business

After login, check the user's role.

user_type = worker

or

user_type = business

Then navigate accordingly.

Database

Your profiles table already has:

user_type

Example:

id	name	user_type
1	Debin	worker
2	Cafe Aroma	business

This single field controls the entire experience.

Flutter Folder Structure

Don't do this:

screens/

home.dart

profile.dart

settings.dart

Instead:

lib/

features/

    worker/

        home/

        jobs/

        profile/

        messages/

        notifications/

    business/

        dashboard/

        post_job/

        applicants/

        analytics/

        messages/

shared/

    login/

    onboarding/

    settings/

    widgets/

core/

Notice that:

Worker screens are completely separated.
Business screens are completely separated.
Shared pages are reused.
App Flow
Splash

↓

Onboarding

↓

Choose Role

↓

Google Login

↓

Check user_type

↓

Worker Home

OR

Business Dashboard
Bottom Navigation
Worker
🗺 Map

💬 Messages

🔔 Notifications

👤 Profile
Business
🏠 Dashboard

💬 Messages

🔔 Notifications

📊 Analytics

👤 Business Profile

Notice they are different.

Router Example

With GoRouter:

if (user.userType == UserType.worker) {
  context.go('/worker/home');
} else {
  context.go('/business/dashboard');
}

This is exactly how many large apps handle role-based navigation.

Shared Widgets

Don't duplicate UI.

Example:

widgets/

PrimaryButton

LoadingIndicator

Avatar

RatingCard

JobCard

BottomSheet

Both worker and business use these.

Shared Models

One Job model.

One Profile model.

One Business model.

No duplicates.

Worker Folder
worker/

home/

map/

job_details/

saved_jobs/

applications/

messages/

notifications/

profile/
Business Folder
business/

dashboard/

post_job/

edit_job/

applicants/

analytics/

messages/

profile/
API

Worker

GET /jobs

POST /applications

GET /saved_jobs

Business

POST /jobs

PATCH /jobs

DELETE /jobs

GET /applications

Same backend.

Different permissions.

How Uber Does It

They actually have separate rider and driver apps, but the backend is shared.

For LocalWork, I wouldn't split into two apps yet because:

Two codebases
Two Play Store listings
More maintenance
Slower development

For an MVP, one app is much better.

My Recommendation
LocalWork

↓

Role Selection

↓

Worker
or
Business

↓

Different Navigation

↓

Different UI

↓

Shared Backend

↓

Shared Database

This is scalable and easier to maintain.

One improvement I'd make

Instead of asking the user to choose a role every time they open the app:

During registration, they select Worker or Business.
Save that in the profiles.user_type field.
On every future launch:
Read the profile.
Automatically open the correct interface.

If you later want to support someone being both a worker and a business owner (for example, a freelancer who also hires helpers), you can extend the schema to support multiple roles. But for LocalWork MVP, a single user_type field is the cleanest and most maintainable approach.