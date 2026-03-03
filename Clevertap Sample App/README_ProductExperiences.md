# CleverTap Product Experiences (Remote Config) Guide

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
