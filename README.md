<img width="590" height="1278" alt="Screenshot 2026-03-05 at 11 57 04 AM" src="https://github.com/user-attachments/assets/38e3f76a-d6cf-4dcb-8269-e46d828c0db8" /># CleverTap Sample App (iOS)

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

## Recent Development Updates

- Rich push flow aligned with current CleverTap template payload handling.
- Carousel-style rich push payload support validated (`pt_img1`, `pt_img2`, `pt_img3` keys).
- Push viewed/impression tracking flow improved when campaign id is present in payload.
- Experiences screen updated with two clear entry options:
  - `Product Experiences`
  - `CleverTap Test Lab`
- Added icon-first option cards for better visibility in Experiences.
- Improved selected-state visibility so active option is clearly identifiable.
- Fixed navigation/back flow from Test Lab to Experiences.

## Branching For Development

- `development` branch is used for ongoing feature development and fixes.
- Recommended: create feature branches from `development` and merge back via PR.

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

## Documentation Index

- Native Display integration: `Clevertap Sample App/README_NativeDisplay.md`
- Product Experiences integration: `Clevertap Sample App/README_ProductExperiences.md`
- PayU integration: `Clevertap Sample App/README_PayU.md`

Additional root summaries:
- `CLEVERTAP_PROFILE_FIXES_SUMMARY.md`
- `DOB_FIXES_COMPLETE_SUMMARY.md`
- `SAVE_CHANGES_FUNCTIONALITY_SUMMARY.md`
- <img width="590" height="1278" alt="Screenshot 2026-03-05 at 11 57 04 AM" src="https://github.com/user-attachments/assets/749d677e-eefb-4977-8971-f942f1046351" />

<img width="590" height="1278" alt="Screenshot 2026-03-05 at 11 57 57 AM" src="https://github.com/user-attachm<img ents/assets/6b4e5c72-c14b-4183-b13a-dfab35a396a9"/>
<img width="590" height="1278" alt="Screenshot 2026-03-05 at 12 00 49 PM" src="https://github.com/user-attachments/assets/e21d5a26-05f5-464b-8c69-de3d11c35563" />
<img width="590" height="1278" alt="Screenshot 2026-03-05 at 12 00 19 PM" src="https://github.com/user-attachments/assets/65971b14-b8b0-4947-a84b-778032a3d16f" />
<img width="590" height="1278" alt="Screenshot 2026-03-05 at 11 59 52 AM" src="https://github.com/user-attachments/assets/6c7de7a6-cf7a-4313-add6-a0d38b05967b" />
<img width="590" height="1278" alt="Screenshot 2026-03-05 at 11 58 35 AM" src="https://github.com/user-attachments/assets/6a4f7b78-2efd-48ef-82fe-c141ad0d36d5" />
<img width="590" height="1278" alt="Screenshot 2026-03-05 at 11 58 17 AM" src="https://github.com/user-attachments/assets/f3a88085-6ecb-4745-ac05-6e877a36d99e" />






