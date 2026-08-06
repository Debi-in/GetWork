# Role Locking Migration & Security Enforcement Note

## Overview
As of the latest security update, GetWork enforces **Permanent Role Locking** for all users upon initial onboarding. A user account is permanently locked to either `worker` or `business`.

---

## 1. Client-Side Enforcement
- **Startup Role Gate (`splash_screen.dart`)**: Reads `user_role` from storage. If present, routes directly to `/home` (Worker) or `/business` (Business), bypassing `/choose-role`.
- **Role Selection Guard (`choose_role_screen.dart`)**: Before setting a role, checks if `user_role` is already set. If set, redirects immediately without overwriting.
- **UI Lock**: Removed all "Switch to Worker Mode" / "Switch to Business Mode" toggles from the app drawer, settings, and profile screens.
- **Support Route**: Added a "Contact Support" entry point for manual review requests if a user picked the wrong role by mistake.

---

## 2. Backend Security Enforcement (`firestore.rules`)
```javascript
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow create: if request.auth.uid == userId;
  allow update: if request.auth.uid == userId
    && (!("role" in resource.data) || request.resource.data.role == resource.data.role);
}
```
This blocks any client-side API call or malicious payload from modifying the `role` field once created.

---

## 3. One-Time Data Migration Strategy for Existing Accounts

For existing documents in the `users/{uid}` collection:
1. **Users with existing `role` field**:
   - Leave `role` as-is.
   - Set `roleLockedAt = Timestamp.now()` to retroactively lock going forward.
2. **Users without `role` field**:
   - Treat as new installations. On next app launch/login, they will be routed to `/choose-role` to pick their permanent role.
