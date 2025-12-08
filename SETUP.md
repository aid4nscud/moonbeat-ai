# Dream Journal - Setup Guide

This guide walks you through setting up the Dream Journal iOS app.

## Prerequisites

- Xcode 15+ (for iOS 17 support)
- Apple Developer Account ($99/year)
- Supabase account (free tier available)
- RevenueCat account (free tier available)
- Replicate account (for video generation)

---

## Step 1: Create Xcode Project

1. Open Xcode → Create New Project
2. Select **iOS App**
3. Configure:
   - Product Name: `DreamJournal`
   - Team: Your Apple Developer Team
   - Organization Identifier: `com.yourcompany`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (we use Supabase)
4. Save to `/Users/aidanscudder/Desktop/dream-journal/`

5. **Copy source files** from `DreamJournal/` folder into your Xcode project

6. **Add Swift Packages** (File → Add Package Dependencies):
   - `https://github.com/supabase/supabase-swift` (2.0.0+)
   - `https://github.com/RevenueCat/purchases-ios` (5.0.0+)

7. **Add Capabilities** (Signing & Capabilities tab):
   - Sign in with Apple
   - In-App Purchase
   - Push Notifications
   - Background Modes → Audio, Background fetch

8. **Update Info.plist** - add these keys:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Record your dreams using voice for easy journaling</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Transcribe your voice recordings into text</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save your dream videos to your photo library</string>
```

---

## Step 2: Supabase Setup

### 2.1 Create Project
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Note your **Project URL** and **anon key**

### 2.2 Run Database Migration
1. Go to SQL Editor in Supabase Dashboard
2. Copy contents of `supabase/migrations/001_initial_schema.sql`
3. Run the SQL

### 2.3 Create Storage Buckets
1. Go to Storage in Supabase Dashboard
2. Create bucket: `dream-audio` (private)
3. Create bucket: `dream-videos` (private)

### 2.4 Enable Apple Auth
1. Go to Authentication → Providers
2. Enable Apple
3. Configure with your Apple Developer credentials:
   - Service ID
   - Team ID
   - Key ID
   - Private Key (.p8 file)

### 2.5 Deploy Edge Functions
```bash
cd supabase
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy generate-video
supabase functions deploy webhook-handler
```

### 2.6 Set Edge Function Secrets
```bash
supabase secrets set REPLICATE_API_TOKEN=your_replicate_token
```

### 2.7 Update iOS App
Edit `DreamJournal/Services/SupabaseService.swift`:
```swift
enum SupabaseConfig {
    static let url = URL(string: "YOUR_SUPABASE_URL")!
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"
}
```

---

## Step 3: Apple Developer Setup

### 3.1 App ID Configuration
1. Go to [developer.apple.com](https://developer.apple.com)
2. Certificates, Identifiers & Profiles → Identifiers
3. Edit your App ID
4. Enable "Sign in with Apple"

### 3.2 Service ID for Supabase
1. Create new Service ID
2. Enable "Sign in with Apple"
3. Configure redirect URL: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`

### 3.3 Create Sign in with Apple Key
1. Keys → Create new key
2. Enable "Sign in with Apple"
3. Download .p8 file (save this!)
4. Note the Key ID

---

## Step 4: RevenueCat Setup

### 4.1 Create Project
1. Go to [revenuecat.com](https://revenuecat.com)
2. Create new project
3. Add iOS app with your Bundle ID

### 4.2 App Store Connect
1. Create subscription group: "Dream Journal Pro"
2. Add products:
   - `com.yourcompany.dreamjournal.pro.monthly` - $4.99/month
   - `com.yourcompany.dreamjournal.pro.annual` - $39.99/year

### 4.3 Configure RevenueCat
1. Connect to App Store Connect (shared secret)
2. Create entitlement: `pro`
3. Create offering: `default`
4. Add packages with your products

### 4.4 Update iOS App
Edit `DreamJournal/Services/PurchaseService.swift`:
```swift
enum PurchaseConfig {
    static let apiKey = "YOUR_REVENUECAT_PUBLIC_API_KEY"
    static let proEntitlement = "pro"
}
```

---

## Step 5: Replicate Setup

1. Go to [replicate.com](https://replicate.com)
2. Create account
3. Get API token from Settings
4. Add to Supabase secrets (Step 2.6)

---

## Step 6: Test the App

1. Build and run on simulator or device
2. Test Sign in with Apple
3. Record a dream
4. Generate a video (uses 1 free credit)
5. Test subscription flow (use Sandbox account)

---

## Deployment Checklist

- [ ] App icon (1024x1024)
- [ ] App Store screenshots
- [ ] Privacy Policy URL
- [ ] Terms of Service URL
- [ ] App Store description
- [ ] Age rating questionnaire
- [ ] Export compliance

---

## Troubleshooting

### Sign in with Apple fails
- Verify Service ID configuration
- Check redirect URL matches Supabase
- Ensure .p8 key is correctly added to Supabase

### Video generation fails
- Check Replicate API token is set
- Verify Edge Functions are deployed
- Check Supabase logs for errors

### Subscription issues
- Use Sandbox Apple ID for testing
- Verify products are "Ready to Submit" in App Store Connect
- Check RevenueCat dashboard for errors

---

## Support

For issues, check:
- Supabase Dashboard logs
- RevenueCat Dashboard
- Xcode console logs
