# CleverTap Sample App (iOS)

This repository contains the CleverTap iOS sample app with integrations for:
- Profile and event tracking
- Product Experiences (Remote Config)
- Native Display
- Push and rich push extensions
- PayU checkout flow

## Project At A Glance

This app is a demo storefront built to showcase end-to-end CleverTap usage in a realistic iOS app flow.

- `Home`: product browsing with Native Display placements (`hero`, `promotion`, `home`)
- `Experiences`: Product Experiences fetch/sync controls for remote UI personalization
- `Inbox`: app inbox and engagement surfaces
- `Cart / Checkout`: cart lifecycle, order events, and PayU payment integration
- `Profile`: user properties, membership tier, notification preferences, and CleverTap dashboard access

## Core Integrations

- Identity and profile sync with CleverTap
- Event tracking across app launch, screen views, search, cart, and checkout
- Product Experiences (remote variables) to change Home UI without app release
- Native Display campaigns for contextual in-app placements
- Push + rich push support with NSE/NCE targets

## Architecture Overview

```text
SwiftUI App (Clevetap_Sample_AppApp)
  |
  +-- Views/
  |    +-- Home, ProductList, Cart, Checkout, Profile
  |    +-- Experiences (ProductExperiencesView, NativeDisplayLabView, CleverTapTestView)
  |    +-- Dashboard (CleverTapProfileDashboardView)
  |
  +-- ViewModels/
  |    +-- AuthViewModel
  |
  +-- Services/
  |    +-- CleverTapService (core SDK wrapper)
  |    +-- CleverTapProductExperiencesService (remote variables)
  |    +-- CleverTapNativeDisplayService (display unit handling)
  |    +-- ProfileService / OrderService / ProductService / PayUService
  |
  +-- Models/
  |    +-- Product / Order / ProductCategory
  |
  +-- Extensions Targets
       +-- Clevertap NSE (rich push processing)
       +-- Clevertap NCE (notification content rendering)
```

### Data and Event Flow

1. User actions in `Views` trigger service calls and tracking events.
2. `CleverTapService` records profile updates/events and reads profile properties.
3. Product Experiences + Native Display services fetch remote content and expose it to UI.
4. Dashboard and Profile surfaces read synced values to show engagement and preference state.

## Quick Demo Flow

1. Login/signup and complete profile details.
2. Open `Experiences` and fetch Product Experiences variables.
3. Return to `Home` to verify remote UI changes and Native Display cards.
4. Add products to cart and complete checkout to generate conversion events.
5. Open Profile dashboard and validate synced properties/engagement metrics.

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
