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

These are consumed by:
- `Views/HomeView.swift`
- `Services/CleverTapProductExperiencesService.swift`

## In-App Usage
1. Open the `Experiences` tab in the app.
2. Tap `Fetch` to download latest variable values.
3. In debug builds, you can tap `Sync (Debug)` to force sync then fetch.
4. Open the `Home` tab and verify UI changes.

## Expected Home Changes
- Header title/subtitle update from remote values.
- Featured section title updates.
- Featured section can be shown/hidden.
- Featured product count is limited by `home_max_featured_products`.

## Notes
- Variable names are case-sensitive.
- If campaigns/segments depend on profile changes, update user profile and fetch again.
- Default values are built into `CleverTapProductExperiencesService` and are used when no remote value is available.

## Recent Changes (Development)

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
