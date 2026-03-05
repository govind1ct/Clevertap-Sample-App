# CleverTap Native Display Integration Guide

This document reflects the latest Profile integration updates and Native Display fixes applied across Home and Profile screens.

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

1. `hero` — Hero banner section on Home screen  
2. `promotion` — Promotional horizontal scroller on Home screen  
3. `home` — General home content blocks  
4. `cart` — Cart recommendations section  
5. `profile` — Offers and content in Profile screen

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

##### For Hero Banners (`hero`)
```json
{
  "location": "hero",
  "type": "hero_banner"
}

