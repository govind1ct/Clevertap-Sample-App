# CleverTap Native Display Integration Guide

## Overview

This app implements CleverTap Native Display functionality to dynamically change content from the CleverTap dashboard. Native Display allows you to show contextual content within your app without interrupting the user experience.

## 🚀 Features Implemented

### ✅ Complete Native Display Integration
- **Delegate Setup**: Proper CleverTapDisplayUnitDelegate implementation
- **Location-based Display**: Content targeted to specific app locations
- **Real-time Updates**: Dynamic content updates from CleverTap dashboard
- **Analytics Tracking**: Automatic view and click tracking
- **Debug Interface**: Comprehensive testing and debugging tools

### 📍 Supported Locations

The app supports native display content in these locations:

1. **`home_hero`** - Hero banner section on Home screen
2. **`product_list_header`** - Top of Product List screen
3. **`cart_recommendations`** - Cart recommendations section
4. **`profile_offers`** - Special offers in Profile screen
5. **`product_detail_related`** - Related products section

## 🛠️ How to Set Up Native Display Campaigns

### Step 1: Access CleverTap Dashboard

1. Log into your CleverTap dashboard
2. Navigate to **Campaigns** → **Native Display**
3. Click **Create Campaign**

### Step 2: Campaign Configuration

#### Basic Settings
- **Campaign Name**: Give your campaign a descriptive name
- **Campaign Type**: Select "Native Display"
- **Target Audience**: Define your audience segments

#### Content Configuration

##### For Hero Banners (`home_hero`)
```json
{
  "location": "home_hero",
  "type": "hero_banner"
}
```

**Content Fields:**
- **Title**: Main headline (e.g., "Special Offer!")
- **Message**: Descriptive text (e.g., "Get 30% off on all crystals")
- **Media URL**: Banner image URL
- **Action URL**: Deep link or web URL
- **Background Color**: Hex color code (e.g., "#FF6B6B")

##### For Product Recommendations (`cart_recommendations`)
```json
{
  "location": "cart_recommendations",
  "type": "product_recommendation"
}
```

**Content Fields:**
- **Title**: "Recommended for You"
- **Message**: "Complete your crystal collection"
- **Media URL**: Product image or promotional image
- **Action URL**: Product detail or category page

##### For Profile Offers (`profile_offers`)
```json
{
  "location": "profile_offers",
  "type": "special_offer"
}
```

**Content Fields:**
- **Title**: "Exclusive Member Offer"
- **Message**: "20% off your next purchase"
- **Media URL**: Offer banner image
- **Action URL**: Offer redemption page

### Step 3: Targeting & Triggers

#### Event-based Triggers
Set up triggers based on user events:

```javascript
// Trigger for home hero display
{
  "event_name": "Native Display Test",
  "event_properties": {
    "location": "home_hero"
  }
}

// Trigger for cart recommendations
{
  "event_name": "Product Added to Cart",
  "event_properties": {
    "category": "crystals"
  }
}
```

#### User Segmentation
Target specific user segments:
- **New Users**: Users who joined in the last 7 days
- **Premium Users**: Users with `user_type = "premium"`
- **Cart Abandoners**: Users who added items but didn't checkout

### Step 4: Custom Extras Configuration

Add these custom extras to target specific locations:

```json
{
  "location": "home_hero",
  "priority": "high",
  "display_duration": "5000",
  "auto_dismiss": "true"
}
```

## 🧪 Testing Your Native Display

### Using the Test Interface

1. Open the app and navigate to the **Test** tab
2. Go to the **Native Display** section
3. Use the test buttons to trigger events:
   - "Test Home_hero Display"
   - "Test Cart_recommendations Display"
   - "Test Profile_offers Display"

### Debug View

1. Tap **"View All Display Units"** to see:
   - All received display units
   - Unit properties and content
   - Live preview of how they'll appear
   - Custom extras and targeting info

### Manual Testing

Trigger test events programmatically:
```swift
CleverTapNativeDisplayService.shared.triggerTestEvent(for: "home_hero")
```

## 📊 Analytics & Tracking

### Automatic Events Tracked

1. **Native Display Units Received**
   ```json
   {
     "Display Units Count": 3,
     "Unit IDs": ["unit_123", "unit_456"],
     "Locations": ["home_hero", "cart_recommendations"]
   }
   ```

2. **Native Display Interaction**
   ```json
   {
     "Unit ID": "unit_123",
     "Action": "Viewed", // or "Clicked"
     "Timestamp": 1640995200
   }
   ```

### Custom Analytics

Track additional metrics:
```swift
// Track when user sees native display
CleverTapService.shared.recordEvent("Native Display Viewed", withProps: [
    "location": "home_hero",
    "campaign_id": "campaign_123",
    "user_segment": "premium"
])
```

## 🎨 Content Guidelines

### Image Specifications

#### Hero Banners
- **Dimensions**: 375x200px (1.875:1 ratio)
- **Format**: JPG, PNG, WebP
- **Size**: Max 500KB
- **Design**: High contrast text, clear CTA

#### Product Recommendations
- **Dimensions**: 300x300px (1:1 ratio)
- **Format**: JPG, PNG
- **Size**: Max 300KB
- **Design**: Product-focused, minimal text

#### Profile Offers
- **Dimensions**: 350x150px (2.33:1 ratio)
- **Format**: JPG, PNG
- **Size**: Max 400KB
- **Design**: Offer-focused, clear value proposition

### Text Guidelines

- **Title**: Max 50 characters, clear and compelling
- **Message**: Max 120 characters, descriptive and actionable
- **Action Text**: Max 20 characters (e.g., "Shop Now", "Learn More")

## 🔧 Advanced Configuration

### Dynamic Content

Use CleverTap's personalization:
```json
{
  "title": "Hi {{first_name}}, Special Offer!",
  "message": "Get {{discount_percentage}}% off your favorite {{preferred_category}}"
}
```

### A/B Testing

Set up variants:
- **Variant A**: Image-focused banner
- **Variant B**: Text-focused banner
- **Variant C**: Video content

### Frequency Capping

Control display frequency:
```json
{
  "frequency_cap": {
    "max_impressions": 3,
    "time_period": "day"
  }
}
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Native Display Not Showing
**Check:**
- CleverTap delegate is properly set
- Campaign is active and targeted correctly
- User matches the audience criteria
- App has internet connection

**Debug:**
```swift
// Check if display units are received
print("Display units count: \(CleverTapNativeDisplayService.shared.displayUnits.count)")

// Check available locations
print("Available locations: \(CleverTapNativeDisplayService.shared.getAvailableLocations())")
```

#### 2. Images Not Loading
**Check:**
- Image URLs are accessible
- Images meet size requirements
- Network connectivity
- Image format is supported

#### 3. Targeting Issues
**Check:**
- User properties are set correctly
- Event properties match campaign triggers
- Audience segments are properly defined

### Debug Commands

```swift
// Refresh display units manually
CleverTapNativeDisplayService.shared.refreshDisplayUnits()

// Trigger test events
CleverTapNativeDisplayService.shared.triggerTestEvent(for: "home_hero")

// Check specific location
let units = CleverTapNativeDisplayService.shared.getDisplayUnitsForLocation("home_hero")
print("Home hero units: \(units.count)")
```

## 📱 Implementation Details

### Service Architecture

```swift
CleverTapNativeDisplayService
├── Display Unit Management
├── Location-based Filtering
├── Analytics Tracking
├── Debug Utilities
└── Testing Methods
```

### View Components

```swift
NativeDisplayView
├── Content Rendering
├── Media Handling
├── Interaction Tracking
└── Action Handling

Location-Specific Views
├── HomeNativeDisplayView
├── ProductListNativeDisplayView
├── CartNativeDisplayView
└── ProfileNativeDisplayView
```

## 🎯 Best Practices

### Campaign Strategy
1. **Start Simple**: Begin with basic text + image campaigns
2. **Test Frequently**: Use A/B testing for optimization
3. **Monitor Performance**: Track CTR and conversion rates
4. **Iterate Based on Data**: Adjust content based on analytics

### Content Strategy
1. **Relevant Content**: Match content to user context
2. **Clear CTAs**: Use action-oriented language
3. **Visual Hierarchy**: Ensure important elements stand out
4. **Mobile-First**: Design for mobile screens

### Technical Best Practices
1. **Optimize Images**: Compress images for faster loading
2. **Handle Errors**: Gracefully handle network failures
3. **Cache Content**: Implement appropriate caching strategies
4. **Monitor Performance**: Track loading times and errors

## 📞 Support

For additional help:
1. Check CleverTap documentation: https://developer.clevertap.com/docs/native-display-ios
2. Contact CleverTap support
3. Review app logs for debugging information

---

**Note**: This implementation follows CleverTap's Native Display iOS SDK guidelines and includes comprehensive testing and debugging tools for easy campaign management. 