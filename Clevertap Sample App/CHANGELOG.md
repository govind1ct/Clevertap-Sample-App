# Changelog

All notable changes to this project will be documented in this file.

## v3.0.0 - 2026-03-05 (Major Update)
- Major redesign of the `Experiences` tab with intro-first flow, premium animations, and smoother section transitions.
- Refined Product Experiences UX with dedicated in-screen enable/disable toggle, clearer guidance, adaptive controls, and reliable back-to-overview behavior.
- Reworked Native Display experience for readability and clarity, including dedicated entry flow and improved scrolling/contrast.
- Upgraded first-time walkthrough coverage and messaging across tabs for clearer onboarding.
- Added CleverTap event tracking when `Experiences` tab is opened.
- Removed redundant `Meet the developer` entry from Profile header and kept Developer as a dedicated tab.
- Improved dark-mode visibility for CleverTap Profile Dashboard by replacing hardcoded light styling with adaptive system-aware colors.
- Added developer profile asset and integrated latest UI/UX polish across onboarding, auth, profile, and experiences surfaces.

## 2026-03-05
- Standardized Native Display locations to `hero`, `promotion`, `home`, `cart`, `profile`.
- Updated HomeView to consume remote config for header, featured section visibility/title, and max featured products.
- Added Profile improvements: manual CleverTap sync CTA, membership tier menu (Bronze/Silver/Gold), notification preference toggles wired to CleverTap DND, and CleverTap dashboard access from Profile.
- Ensured Profile Native Display renders units from `profile` location and refreshes after manual sync.
- Improved error and loading handling for product experiences fetch and product fetch retry path.

## 2026-02-28
- Introduced `CleverTapProductExperiencesService` with default values and fetch flow.
- Hooked up Experiences tab controls for Fetch and Debug Sync.
- Initial integration of Home UI bindings to remote variables.

## 2026-02-20
- Set up base Native Display service and container views.
- Added location-specific views for Home, Cart, Profile.
- Established README guidance for campaign setup and testing.
