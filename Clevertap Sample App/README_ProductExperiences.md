# CleverTap Product Experiences (Remote Config) Guide

## Development Workflow
Use `development` as the main branch for active development and fixes.

Recommended flow:
1. Create feature/fix branch from `development`.
2. Commit scoped changes with clear messages.
3. Raise PR back to `development`.
4. Validate build and manual testing before merge.

## What Is Integrated
The app now uses CleverTap Product Experiences variables to control Home UI in real time:

- `home_header_title` (String)
- `home_header_subtitle` (String)
- `home_featured_section_title` (String)
- `home_show_featured_section` (Boolean)
- `home_max_featured_products` (Integer)
- Profile sync improvements and Native Display locations alignment (hero, promotion, home, cart, profile)

These are consumed by:
- `Views/HomeView.swift`
- `Services/CleverTapProductExperiencesService.swift`

## In-App Usage
1. Open the `Experiences` tab in the app.
2. Tap `Fetch` to download latest variable values.
3. In debug builds, you can tap `Sync (Debug)` to force sync then fetch.
4. Open the `Home` tab and verify UI changes.
5. Open the `Profile` tab and verify profile-driven UI (completion %, membership tier, notification toggles) and Native Display content from the `profile` location.

## Expected Home Changes
- Header title/subtitle update from remote values.
- Featured section title updates.
- Featured section can be shown/hidden.
- Featured product count is limited by `home_max_featured_products`.
- Native Display locations standardized to `hero`, `promotion`, and `home` for the Home screen.

## Profile Updates
- Profile screen improvements:
  - Manual CleverTap sync CTA (Sync Profile Data) to push latest profile info.
  - Membership tier menu with Bronze/Silver/Gold and safe defaulting.
  - Notification preferences wired to CleverTap DND (push/email/SMS).
  - CleverTap dashboard entry point from Profile.
  - Native Display integration for `profile` location via `ProfileNativeDisplayView`.
- Data sent to CleverTap includes name, email, phone, gender, DOB, location, membership tier, profile completion, and engagement opt-ins.
- Pull-to-refresh on Profile reloads profile and orders; sync is throttled to avoid redundant calls (ensure service-level checks).

## Notes
- Variable names are case-sensitive.
- If campaigns/segments depend on profile changes, update user profile and fetch again.
- Default values are built into `CleverTapProductExperiencesService` and are used when no remote value is available.

## Recent Changes (Development)

### Latest UI + Demo Updates (March 2026)
- Experiences UI has been redesigned with a premium visual treatment:
  - upgraded hero/header, selectors, status cards, and action CTA styling.
  - improved spacing, hierarchy, and readability for client demos.
- Native Display Lab UI has been redesigned to match the Experiences visual language:
  - premium header card, two-column location trigger grid, and upgraded refresh/debug actions.
- Product Experiences demo controls were added and hardened:
  - local demo presets (`Luxury`, `Festive`, `Reset`) for quick walkthroughs.
  - `Demo Mode Lock` to keep local demo values stable and prevent remote overwrite.
- Product Experiences remote fetch can now be disabled centrally in code:
  - `CleverTapProductExperiencesService.isFeatureEnabled` controls whether dashboard variables are applied.
  - when disabled, app defaults are used and remote fetch/sync paths are blocked.
- App icon asset set has been refreshed with updated icon file names in `AppIcon.appiconset`.

### Push and Rich Push
- Restored rich push behavior for current CleverTap templates.
- Added carousel-compatible handling for template payload keys (`pt_img1`, `pt_img2`, `pt_img3`).
- Updated push viewed tracking flow so impressions are recorded when campaign id is available.

### Experiences Tab UX
- Added two clear options in Experiences:
  - `Product Experiences`
  - `CleverTap Test Lab`
- Improved option visibility with icon-first cards.
- Improved selected-state visibility for active option.
- Fixed navigation so users can return from Test Lab to Experiences.
### Profile & Native Display
- Standardized Native Display locations: `hero`, `promotion`, `home`, `cart`, `profile`.
- Fixed Profile screen to refresh Native Display after manual sync.
- Improved membership tier handling and profile completion calculation.
- Added safeguards to avoid redundant CleverTap syncs during refresh.

For a complete history of changes, see [CHANGELOG.md](CHANGELOG.md).
