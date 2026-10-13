# Portrait launch waiting screen

Implemented 12 October 2026 using the supplied reference and existing chase background, SVG logo, paint-stroke button, and Material social icons.

- All authenticated Home routes use LaunchAccessGate, including login, signup, Facebook login, session restoration, and opened notifications. Guests retain their existing flow.
- The server's `canPlay` is authoritative. `invited` without `canPlay` remains waiting. Approved accounts proceed to existing profile setup/Home.
- Waiting screen requests portrait orientation; other routes use the existing landscape orientation. Navigation restores portrait when returning from Profile.
- Existing POST /api/waitlist/join and GET /api/waitlist/me supply live access and position. The screen refreshes on entry, manually, and every 30 seconds while visible and resumed. Existing app resume/push refreshes remain wired.
- Bonus display is 200 plus 100 per server-verified referral. The base bonus is once per account display, never accumulated on repeat logins. Sharing, cancellation, and pending referrals do not add points.
- This bonus display is a temporary calculation, not a stored wallet or server points ledger. Queue rank remains the backend's verified-referrals order; points are not sent to the backend.
- Share uses the server referral link and native share sheet, with copy-link fallback.
- The reference countdown is replaced by the real queue position because no launch deadline/countdown is provided by the API.
- Official social page URLs were not supplied. Footer icons are currently display-only; they do not claim follow verification.
- Push remains opt-in and requires existing Firebase configuration.

Preview: deliverables/launch-waitlist-preview.png (mock account with queue position 45 and no verified referrals).
