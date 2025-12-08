# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Moonbeat AI (formerly Dream Journal) is an iOS app (SwiftUI, iOS 17+) that records dreams via voice, analyzes them with on-device AI, and generates artistic videos using cloud APIs. It uses a freemium model with Supabase backend and RevenueCat for subscriptions.

## MCP Servers

- **RevenueCat MCP** - Query subscriber data, revenue metrics, and entitlements directly

## Architecture

### iOS App (DreamJournal/)
- **Services layer**: Singleton services accessed via `.shared` pattern
  - `AuthService` - Sign in with Apple via Supabase Auth
  - `DreamService` - CRUD operations for dreams
  - `SpeechService` - Voice recording + Apple Speech transcription
  - `DreamAnalysisService` - On-device NLP using NaturalLanguage framework
  - `VideoService` - Video generation via Supabase Edge Functions
  - `PurchaseService` - RevenueCat subscriptions with PaywallView & Customer Center
  - `SupabaseService` - Supabase client singleton

- **State management**: Services are `@MainActor` + `ObservableObject`, injected via `.environmentObject()`

- **Models**: Dual model pattern - DTOs (Codable) for Supabase API, SwiftData models for local cache

- **Utilities**:
  - `EntitlementHelpers.swift` - View modifiers for gating features behind paywall

### Backend (supabase/)
- **Edge Functions** (Deno/TypeScript):
  - `generate-video/` - Proxies to Replicate API, manages credits
  - `webhook-handler/` - Receives Replicate completion callbacks, stores videos

- **Database**: PostgreSQL with Row Level Security (users can only access own data)
  - Tables: `profiles`, `dreams`, `video_jobs`
  - Storage buckets: `dream-audio`, `dream-videos`

## Key Commands

### Supabase Edge Functions
```bash
cd supabase
supabase functions deploy generate-video
supabase functions deploy webhook-handler
supabase secrets set REPLICATE_API_TOKEN=<token>
```

### Database Migrations
Run SQL in Supabase Dashboard SQL Editor:
```bash
# Apply schema
cat supabase/migrations/001_initial_schema.sql
```

## Configuration Files

Before running, update these placeholder values:

1. `DreamJournal/Services/SupabaseService.swift`:
   - `SupabaseConfig.url` - Your Supabase project URL
   - `SupabaseConfig.anonKey` - Your Supabase anon key

2. `DreamJournal/Services/PurchaseService.swift`:
   - `PurchaseConfig.apiKey` - RevenueCat public API key (configured)
   - `PurchaseConfig.proEntitlement` - "Moonbeat AI Pro"

## RevenueCat Integration

### SDK Setup
- Package: `https://github.com/RevenueCat/purchases-ios-spm.git` (v5.x)
- Products: `RevenueCat` and `RevenueCatUI`
- Requires In-App Purchase capability in Xcode

### Entitlement
- **Identifier**: `Moonbeat AI Pro`
- **Products**: `monthly`, `yearly`, `lifetime`

### Key Components
- `PaywallView` - RevenueCat's remotely configurable paywall (design in Dashboard)
- `CustomerCenterView` - Self-service subscription management for Pro users
- `presentPaywallIfNeeded()` - View modifier to auto-present paywall
- `purchaseService.isPro` - Check if user has active Pro entitlement

### Entitlement Checking Patterns
```swift
// Check Pro status
if purchaseService.isPro { /* allow feature */ }

// Gate a button
Button("HD Export") { }.requiresPro { exportHD() }

// Auto-present paywall
.presentPaywallIfNeeded()

// Get subscription details
let details = purchaseService.subscriptionDetails
```

## Data Flow

1. **Dream Recording**: `RecordDreamView` → `SpeechService` (transcription) → `DreamAnalysisService` (themes/emotions) → `DreamService` (save to Supabase)

2. **Video Generation**: `DreamDetailView` → `VideoService` → Supabase Edge Function → Replicate API → Webhook → Supabase Storage

3. **Subscriptions**: `PurchaseService` syncs RevenueCat entitlements to Supabase `profiles.subscription_tier`

## Freemium Model

- **Free tier**: 3 video credits (tracked in `profiles.credits_remaining`)
- **Pro tier**: 30 videos per month (quota resets monthly, checked via `purchaseService.isPro`)
- **Lifetime**: One-time purchase, no expiration, 30 videos per month
- Credits deducted in Edge Function, refunded on generation failure
- Subscription status synced to Supabase `profiles.subscription_tier`

## Pro Features

- **30 dream videos per month** - Monthly quota that resets on the 1st
- **AI Dream Interpretation** - Personalized analysis via `analyze-dream` Edge Function
- **Full Emotional Insights** - Complete theme/emotion breakdown, emotional trend charts
- **Pattern Analysis** - Day of week patterns, year in dreams
- **Priority Processing** - Skip the queue for video generation
