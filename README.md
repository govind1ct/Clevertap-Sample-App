# CleverTap Sample App (iOS)

This repository contains the CleverTap iOS sample app with integrations for:
- Profile and event tracking
- Product Experiences (Remote Config)
- Native Display
- Push and rich push extensions
- PayU checkout flow

## Major Update (March 2026)

- Complete redesign of the CleverTap Profile Dashboard UI with premium visual styling and improved information hierarchy.
- Improved dashboard header status indicators for profile properties, push state, sync state, and last refresh.
- Hardened engagement metric parsing to correctly handle CleverTap values returned as `Int`, `NSNumber`, or `String`.
- Reinforced app launch engagement tracking by triggering launch tracking during app startup.
- Preserved all dashboard functionality (refresh, sync, export, clear cache) while upgrading UI quality for demos and client walkthroughs.

## Documentation

- Product Experiences: `Clevertap Sample App/README_ProductExperiences.md`
- Native Display: `Clevertap Sample App/README_NativeDisplay.md`
- PayU Checkout: `Clevertap Sample App/README_PayU.md`
