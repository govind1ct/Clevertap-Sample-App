# Changelog

All notable changes to this project will be documented in this file.

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

