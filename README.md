# KovaiWorks - Velaiku Aalu Ready

Real-time hyperlocal gig platform connecting Coimbatore mills, factories
and event organisers with daily wage workers.

**Live demo:** https://kovaiworks.web.app

**Demo logins (test numbers):** 

Worker 9999900001,

Employer 9999900002, 

OTP 123456

## Features
- Phone OTP login, role-based flow (Worker / Employer)
- Tamil and English (runtime toggle)
- Industrial and Event job categories
- Worker availability toggle and live location (realtime)
- Employer map of available workers (OpenStreetMap)
- Job requests with live accept / reject
- Live worker tracking
- Real-time chat (Firestore)
- Simulated UPI payment, PDF bill, rating

## Tech stack
Flutter, Riverpod, go_router, Firebase Auth, Cloud Firestore,
flutter_map (OpenStreetMap), geolocator, pdf/printing, intl (l10n)

## Architecture
Feature-first folders (`features/auth`, `owner`, `worker`, `chat`,
`payment`, `settings`), shared widgets and core theme/router.

## Design decisions
- Zero-cost stack: OpenStreetMap instead of Google Maps, Firestore
  listeners instead of Cloud Functions
- Firestore security rules protect `role` and `verified` fields

## Known limitations (honest)
- Aadhaar: only last 4 digits stored, verified badge is manual (real
  eKYC needs a licensed provider)
- Payment is simulated; Razorpay needs a key and a server for signature
  verification and worker payouts
- No background push (FCM needs a server / Blaze plan)
- `users` documents are readable by any signed-in user (needed for map);
  production would split a public profile collection
- Location writes throttled (50 m) to stay within the free quota

## Future scope
Razorpay + RazorpayX payouts, FCM push, Cloud Functions, admin panel
for verification, geohash queries for scale.
