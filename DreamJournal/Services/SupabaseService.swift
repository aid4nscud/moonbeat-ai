import Foundation
import Supabase

// MARK: - Configuration

enum SupabaseConfig {
    /// Moonbeat AI Supabase project URL
    static let url = URL(string: "https://iwaivizzjizagrcvoeav.supabase.co")!
    /// Moonbeat AI Supabase anon key
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3YWl2aXp6aml6YWdyY3ZvZWF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5NTY0ODEsImV4cCI6MjA4MDUzMjQ4MX0.IjnOXJFaVzJGG3KnGma3WtRPou783BjFKZLbDQHDCRo"
}

// MARK: - Supabase Client Singleton

final class SupabaseService: Sendable {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}

// MARK: - Database Tables

enum SupabaseTable: String {
    case profiles
    case dreams
    case videoJobs = "video_jobs"
}

// MARK: - Storage Buckets

enum SupabaseBucket: String {
    case audio = "dream-audio"
    case videos = "dream-videos"
}

// MARK: - Edge Functions

enum SupabaseFunction: String {
    case generateVideo = "generate-video"
    case checkVideoStatus = "check-video-status"
    case webhookHandler = "webhook-handler"
}
