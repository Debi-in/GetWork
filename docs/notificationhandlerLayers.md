┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: ADMIN DASHBOARD                                    │
│  Internal team tool → manual/broadcast sends                 │
│  "Try new feature", promotions, announcements                │
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: NOTIFICATION ENGINE (your backend)                 │
│  Listens to real events in your database/app                 │
│  → new job posted, application accepted, message sent        │
│  Decides: WHO to notify, WHAT to say, WHERE to route them     │
├─────────────────────────────────────────────────────────────┤
│  LAYER 3: FCM (Firebase) → APNs (Apple) / FCM (Android)       │
│  Actual delivery to the device                                │
├─────────────────────────────────────────────────────────────┤
│  LAYER 4 (missing from your diagram): THE DEVICE ITSELF       │
│  Flutter app receives it, routes via GoRouter, logs to        │
│  Analytics — this is the client-side handling code            │
└─────────────────────────────────────────────────────────────┘