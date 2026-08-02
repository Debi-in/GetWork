LocalWork MVP Development Documentation v1.0

Project Name: GetWork

Version: MVP 1.0

Platform: Android

Framework: Flutter

Backend: Supabase
vrecal , github for repo

Status: Prototype Development

Goal: Build a complete working MVP that demonstrates the full hiring workflow before adding authentication and production features.


1. Project Vision

GetWork is a map-first local hiring platform that allows workers to discover nearby part-time and temporary jobs while enabling businesses to hire trusted local workers quickly.

Unlike traditional job portals, GetWork focuses on location-first hiring.

2. Development Philosophy
Phase 1

Focus only on user experience.

Everything works locally or fill own for testing.
for now dummpy login ui and let enter without authentication.
just dummy login with google page

No login.

No authentication.



The objective is to complete the entire application flow.

Phase 2

Replace dummy data with Supabase.

Connect database.

Store jobs.

Store profiles.

Store applications.

Phase 3

Add authentication.

Google Login.

Phone Login.

User sessions.

Permissions.

Phase 4

Testing.

Optimization.

Bug fixing.

Beta release.

3. MVP Objectives

The MVP should prove one thing:

Can businesses post nearby jobs and can workers successfully discover and apply for those jobs?

If yes,

continue development.

4. Technology Stack
Frontend

Flutter (Latest Stable)

Material Design 3

Backend

Supabase

PostgreSQL

Storage

Realtime (Later)

Maps

Google Maps Flutter SDK

Notifications

Firebase Cloud Messaging (Later)

Hosting

Supabase

Vercel (Landing Page)

5. Android Requirements

Minimum SDK

Android 7.0 (API 24)

Recommended Target

Android 15+

Flutter SDK

Latest Stable

Dart

Latest Stable

6. Application Flow
Splash
logo and app name 
↓

Onboarding


↓

Welcome

↓

Home Map

↓

Job Details

↓

Apply

↓

Application Success

↓

Profile

↓

Settings

Authentication is skipped during MVP.

7. MVP Features
Worker
Home

Interactive map

Nearby jobs

Floating salary markers

Search

Filters

Current location

Jobs

View job

Business details

Salary

Distance

Requirements

Shift time

Apply

Profile

Static profile

Completed jobs

Skills

Rating

Availability

Notifications

Prototype notifications

Static

Settings

Theme

Language

About

Privacy

Business

Dashboard

Post Job

Manage Jobs

Applicants

Business Profile

Statistics

Job Posting

Title

Salary

Category

Location

Date

Time

Workers Needed

Requirements

Publish

Search

Distance

Category

Salary

Today

Urgent

8. Features Excluded from MVP

No authentication

No payments

No chat

No live tracking

No verification

No push notifications

No QR attendance

No AI

No premium

9. Authentication Plan

Authentication will be implemented only after the complete MVP is finished.

Phase 1

No login.

The app opens directly.

Uses dummy profile.

Phase 2

Google Sign-In

Primary login system.

Fast.

Reliable.

Free.

Phase 3

Phone Login

OTP verification.

No password.

User enters:

Phone Number

↓

Receive OTP

↓

Verify

↓

Login

Password authentication will not be implemented.

10. User Types

Worker

Business

Admin (Later)

11. Database Structure

Users

Profiles

Businesses

Jobs

Applications

Ratings

Notifications

Bookmarks (Later)

12. Folder Structure
lib/

core/

constants/

theme/

utils/

services/

models/

screens/

widgets/

features/

authentication/

map/

jobs/

profile/

business/

notifications/

settings/

13. Design Principles

Warm

Friendly

Modern

Minimal

Fast

Map-first

No clutter

Easy navigation

Material Design 3

Rounded corners

Soft colors

14. UI Guidelines

Primary Color

Sage Green

Accent

Warm Orange

Background

Warm Ivory

Cards

Rounded

24px radius

Buttons

Large

Readable

Touch-friendly

15. Map Experience

The map is the core product.

Users immediately see nearby jobs.

Jobs appear as floating salary markers.

Clicking a marker opens a bottom sheet.

The bottom sheet contains:

Business

Salary

Distance

Time

Requirements

Apply button

16. Testing Plan
Device Testing

Android 7

Android 8

Android 9

Android 10

Android 11

Android 12

Android 13

Android 14

Android 15

Screen Sizes

5 inch

6 inch

6.5 inch

Tablet (Optional)

Performance Testing

Cold Start

Memory

Navigation

Scrolling

Map Performance

Search Speed

Marker Rendering

Functional Testing

Open app

View map

Tap marker

Open details

Apply

Navigate profile

Navigate dashboard

Post job

Search jobs

Filter jobs

UI Testing

No overflow

No clipping

Responsive layouts

Consistent spacing

Dark mode (Later)

17. Development Milestones
Sprint 1

Project setup

Theme

Navigation

Folder structure

Basic UI

Sprint 2

Map

Job markers

Bottom sheet

Filters

Sprint 3

Worker profile

Business dashboard

Job posting

Applications

Sprint 4

Supabase integration

Database

Storage

Real data

Sprint 5

Google Login

Phone OTP

User sessions

Sprint 6

Testing

Bug fixes

Performance optimization

Beta release

18. Success Criteria

The MVP is considered successful when:

Users can browse nearby jobs on the map.
Businesses can post jobs.
Workers can apply.
Job data is stored in Supabase.
The app runs smoothly on Android 7 and above.
Navigation is intuitive.
Core features are stable.
19. Future Features (Post-MVP)
Business verification
Worker identity verification
Real-time chat
Push notifications
GPS navigation to workplaces
QR code check-in/check-out
In-app payments
AI-powered job matching
Reviews and dispute resolution
Web dashboard
Analytics
Multi-language support (English/Nepali)
Referral program
Premium subscriptions
Admin moderation panel
Final Development Rule

Every feature added to LocalWork must answer one question: Does this make it faster or easier for a nearby business to hire a nearby worker?