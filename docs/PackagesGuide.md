# GetWork — Packages Guide
_Last Updated: 2026-08-02_

All Flutter packages used in the GetWork app, their purpose, and when they become active.

---

## Core Packages

| Package | Version | Purpose | Active Phase |
|---------|---------|---------|-------------|
| `go_router` | ^14.8.1 | Declarative navigation / routing | Phase 1 |
| `flutter_riverpod` | ^2.6.1 | State management | Phase 1 |
| `equatable` | ^2.0.7 | Value equality for models | Phase 1 |
| `logger` | ^2.4.0 | Structured debug logging | Phase 1 |

## Maps & Location

| Package | Version | Purpose | Active Phase |
|---------|---------|---------|-------------|
| `google_maps_flutter` | ^2.10.0 | Interactive map display | Sprint 2 |
| `geolocator` | ^13.0.2 | GPS position + distance | Sprint 2 |
| `geocoding` | ^3.0.0 | Address ↔ coordinates | Sprint 2 |
| `permission_handler` | ^11.3.1 | Runtime permission requests | Sprint 2 |

## Backend (Phase 2)

| Package | Version | Purpose | Active Phase |
|---------|---------|---------|-------------|
| `supabase_flutter` | ^2.8.4 | Database, Auth, Storage | Phase 2 |

## Firebase (Phase 3)

| Package | Version | Purpose | Active Phase |
|---------|---------|---------|-------------|
| `firebase_core` | ^3.13.1 | Firebase initialization | Phase 3 |
| `firebase_messaging` | ^15.2.5 | Push notifications (FCM) | Phase 3 |
| `google_sign_in` | ^6.2.2 | Google OAuth sign-in | Phase 3 |

## UI & Design

| Package | Version | Purpose | Active Phase |
|---------|---------|---------|-------------|
| `cached_network_image` | ^3.4.1 | Cached image loading | Phase 2 |
| `flutter_svg` | ^2.0.17 | SVG icon rendering | Phase 1 |
| `shimmer` | ^3.0.0 | Loading skeleton animations | Phase 2 |
| `lottie` | ^3.3.1 | Lottie JSON animations | Phase 1 |
| `flutter_animate` | ^4.5.2 | Micro-animations & transitions | Phase 1 |

## Utilities

| Package | Version | Purpose | Active Phase |
|---------|---------|---------|-------------|
| `shared_preferences` | ^2.3.5 | Local key-value storage | Phase 1 |
| `intl` | ^0.20.2 | Date/time/number formatting | Phase 1 |
| `url_launcher` | ^6.3.1 | Open external links / phone | Phase 1 |
| `connectivity_plus` | ^6.1.3 | Network connection check | Phase 1 |
| `image_picker` | ^1.1.2 | Camera / gallery photo picker | Phase 2 |
| `path_provider` | ^2.1.5 | App file system paths | Phase 2 |
| `uuid` | ^4.5.1 | Generate unique IDs | Phase 1 |

## Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_lints` | ^5.0.0 | Code style linting |
| `build_runner` | ^2.4.14 | Code generation runner |
| `riverpod_generator` | ^2.4.3 | Riverpod annotation codegen |
| `json_serializable` | ^6.9.4 | JSON model codegen |
| `json_annotation` | ^4.9.0 | JSON annotation support |

---

## How to Add a New Package

```bash
flutter pub add <package_name>
```
Or via MCP `pub` tool with command `add` and `packageNames: ["<package_name>"]`.

## How to Upgrade All Packages

```bash
flutter pub upgrade
```
