# CleverTap Sample App (iOS)

Production-style SwiftUI sample app integrated with CleverTap, Firebase, Product Experiences, App Inbox, Native Display, checkout flow improvements, and modern onboarding/auth UI.

## Core Features

- CleverTap user profile + event tracking
- CleverTap In-App + Native Display + App Inbox integration
- Product Experiences / remote variable support
- Enhanced onboarding experience with branded assets
- Revamped Login/Signup flow
- Email auth + Google auth support (Firebase)
- Cart, checkout, address/pincode validation, profile management
- Firebase Storage-backed profile image handling

## Recent UX/Auth Updates

- Full redesign of onboarding screens with CleverTap-focused content
- Logout/guest routing now ensures onboarding is shown before auth
- Login and Signup screens revamped to match onboarding visual quality
- Google button styling updated to a Google-like look
- Added Google auth interaction events:
  - `Google Auth Clicked` (`Source`: `login`/`signup`)
  - `Google Auth Failed` (`Source`: `login`/`signup`)

## Project Structure (main app target)

- `Clevertap Sample App/Services/` – CleverTap, Firebase, checkout, profile, product services
- `Clevertap Sample App/ViewModels/` – auth state and sign-in flows
- `Clevertap Sample App/Views/` – all SwiftUI screens
- `Clevertap Sample App/Assets.xcassets/` – app/theme/brand image assets

## Google Sign-In Setup

1. Add package:
   - `https://github.com/google/GoogleSignIn-iOS`
2. Link `GoogleSignIn` to app target.
3. In Firebase Console, enable **Authentication > Sign-in method > Google**.
4. Add URL type using reversed client ID from `GoogleService-Info.plist`.
5. Ensure `GoogleService-Info.plist` is included in app target.

Note: The code uses `#if canImport(GoogleSignIn)` so build remains safe if the SDK is temporarily missing.

## Build

- Xcode project: `Clevertap Sample App.xcodeproj`
- Main target: `Clevertap Sample App`
- iOS: 15+

## Notes

- Native display integration details: `Clevertap Sample App/README_NativeDisplay.md`
- Product experiences setup: `Clevertap Sample App/README_ProductExperiences.md`
- PayU setup: `Clevertap Sample App/README_PayU.md`
