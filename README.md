# CleverTap Sample App (iOS)

CleverTap Sample App is a SwiftUI commerce demo app built to showcase a realistic end-to-end CleverTap integration on iOS.

This version includes a premium V4 storefront, Product Experiences, Native Display, App Inbox, Push + Rich Push, PayU checkout, profile management, and an internal admin console for operating catalog and campaign surfaces.

**Current Release:** `v4.0.0`

## What V4 Adds

- Rebuilt `Home` screen with a cleaner premium commerce layout
- Modularized Home screen into reusable SwiftUI components
- Updated Spotlight and Collection presentation for better maintainability
- Improved tab bar styling and icon system
- Added stronger light/dark mode compatibility across Home UI
- Refined category browsing and featured product presentation
- Expanded admin tooling for banners, products, orders, and audit logs
- Preserved CleverTap integration flows while improving demo quality and code structure

## Core Capabilities

- CleverTap identity, profile, and event tracking
- Product Experiences / remote personalization variables
- Native Display rendering and placement handling
- App Inbox integration and inbox-trigger flows
- Push notifications with NSE and NCE targets
- PayU checkout flow for purchase demo journeys
- Cart, checkout, order creation, and profile editing flows
- Admin dashboard for live content and commerce operations

## App Modules

### Storefront

- `HomeView`: premium editorial storefront with campaigns, spotlight products, collection grid, and Native Display placements
- `ProductListView`: browse products in a dedicated list flow
- `ProductDetailView`: product detail, add-to-cart, and purchase action surface
- `CartView`: cart review and quantity management
- `CheckoutView`: checkout flow with order creation and PayU handoff

### CleverTap Demo Surfaces

- `CleverTapTestView` and `CleverTapTestViewV2`: test/event and integration demo screens
- `ProductExperiencesView`: remote-variable driven personalization surface
- `NativeDisplayLabView`: Native Display testing and validation screen
- `AppInboxView`: inbox rendering and interaction surface
- `NotificationSettingsView`: notification preference and permissions surface

### Profile and Settings

- `ProfileView`: user profile, dashboard access, and account utilities
- `EditProfileView`: profile editing flow
- `SettingsView`: app-level toggles and feature settings
- `CleverTapProfileDashboardView`: profile and engagement summary surface

### Admin Console

- `AdminDashboardView`: admin landing surface
- `AdminHeroBannersView`: create and manage hero/campaign banners
- `AdminOrdersView`: review placed orders
- `AdminAuditLogView`: inspect admin activity logs
- `AdminDashboardHeaderView`: shared entry point into admin operations

Admin services:
- `AdminProductService`
- `AdminHeroBannerService`
- `AdminOrderService`
- `AdminAuditLogService`
- `AdminProductImageUploadService`
- `AdminAuditLogger`

## Technical Highlights

- SwiftUI-first app architecture
- Shared app state through environment objects where appropriate
- Firebase-backed product, profile, and admin content flows
- CleverTap wrapped through focused service layers
- Home screen refactored into reusable components:
  - `HomeCommerceComponents.swift`
  - `HomeSectionViews.swift`
- Theme-driven typography and styling via:
  - `ThemeManager`
  - `ThemeModels`

## Project Structure

```text
Clevertap Sample App
├── Models
│   ├── HeroBanner.swift
│   ├── Order.swift
│   ├── Product.swift
│   └── ProductCategory.swift
├── Services
│   ├── CleverTapService.swift
│   ├── CleverTapProductExperiencesService.swift
│   ├── CleverTapNativeDisplayService.swift
│   ├── CleverTapInAppService.swift
│   ├── ProductService.swift
│   ├── OrderService.swift
│   ├── ProfileService.swift
│   ├── PayUService.swift
│   ├── ThemeManager.swift
│   └── Admin* services
├── ViewModels
│   └── AuthViewModel.swift
├── Views
│   ├── HomeView.swift
│   ├── MainTabView.swift
│   ├── CartView.swift
│   ├── CheckoutView.swift
│   ├── ProfileView.swift
│   ├── AppInboxView.swift
│   ├── ProductExperiencesView.swift
│   ├── NativeDisplayLabView.swift
│   ├── Admin*.swift
│   └── Common/
│       ├── HomeCommerceComponents.swift
│       ├── HomeSectionViews.swift
│       ├── ProductDetailView.swift
│       ├── NativeDisplayContainerView.swift
│       └── NativeDisplayView.swift
├── Clevertap NSE
└── Clevertap NCE
```

## CleverTap Integration Areas

### Profile and Identity

- login / signup flows
- profile update sync
- user property updates
- profile dashboard rendering

### Event Tracking

- app launch and screen views
- product browsing and selection
- search and category exploration
- add to cart and checkout actions
- banner interaction and campaign taps

### Product Experiences

- fetch and apply remote variables
- personalize Home content and layout behavior
- support demo/testing workflows in dedicated screens

### Native Display

- render display units in Home and other placements
- support vertical and horizontal layouts
- provide lab/test surface for validation

### Push / Rich Push

- standard push integration
- Notification Service Extension (`Clevertap NSE`)
- Notification Content Extension (`Clevertap NCE`)

## Checkout and Orders

The commerce flow supports:

- add to cart
- cart persistence
- checkout handoff
- PayU integration
- order creation and storage
- order visibility inside admin tools

Additional PayU details are documented in:
- `Clevertap Sample App/README_PayU.md`

## Admin Workflows

The app now includes an internal admin track for demo operations.

Admin users can:
- manage hero banners
- manage products and product media
- inspect orders
- review audit logs
- validate storefront content changes against the user-facing Home experience

This makes the sample app more useful for internal demos, solution walkthroughs, and operational showcases where both marketer and admin flows need to be shown.

## Documentation

- `Clevertap Sample App/README_ProductExperiences.md`
- `Clevertap Sample App/README_NativeDisplay.md`
- `Clevertap Sample App/README_PayU.md`

## Setup Notes

Prerequisites:
- Xcode
- Firebase configuration via `GoogleService-Info.plist`
- CleverTap SDK configuration
- PayU credentials if checkout demo is required

Important files:
- `Clevertap Sample App/Clevetap_Sample_AppApp.swift`
- `Clevertap Sample App/Services/AppDelegate.swift`
- `Clevertap Sample App/GoogleService-Info.plist`

## Recommended Demo Flow

1. Sign in or sign up
2. Open Home and show premium storefront + campaign surfaces
3. Demonstrate Product Experiences / Native Display updates
4. Open a product and add it to cart
5. Walk through checkout and order creation
6. Open Profile and dashboard surfaces
7. Open Admin and show banner / order / audit capabilities

## Built By

This app was built by **Govind Pathak**.

- Email: `govind.pathak@clevertap.com`
- Role: Manager - Technical Accounts - Customer Solutions - Customer Success

## Version History

### v4.0.0

- rewritten Home architecture with extracted section components
- upgraded premium storefront presentation
- improved maintainability of Home UI code
- updated tab bar styling and icons
- improved theme compatibility across light and dark mode
- expanded README and admin documentation

### v3.0.0

- major profile dashboard redesign
- improved engagement metric parsing
- launch tracking reinforcement
- stronger demo-ready dashboard presentation
