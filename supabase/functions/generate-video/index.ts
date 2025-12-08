// Dream Journal - Video Generation Edge Function
// This function proxies requests to Replicate API and manages video generation

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface GenerateVideoRequest {
  dream_id: string;
  prompt: string;
}

interface ReplicatePrediction {
  id: string;
  status: string;
  output?: string | string[];
  error?: string;
  urls?: {
    get: string;
  };
}

interface ProQuotaStatus {
  can_generate: boolean;
  videos_used: number;
  videos_remaining: number;
  quota_limit: number;
  resets_at: string;
}

// Poll for prediction completion
async function pollPrediction(
  predictionId: string,
  token: string,
  maxAttempts = 60
): Promise<ReplicatePrediction> {
  for (let i = 0; i < maxAttempts; i++) {
    const response = await fetch(
      `https://api.replicate.com/v1/predictions/${predictionId}`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );

    const prediction: ReplicatePrediction = await response.json();

    if (prediction.status === "succeeded" || prediction.status === "failed") {
      return prediction;
    }

    // Wait 2 seconds before next poll
    await new Promise((resolve) => setTimeout(resolve, 2000));
  }

  throw new Error("Prediction timed out");
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const replicateToken = Deno.env.get("REPLICATE_API_TOKEN");

    if (!replicateToken) {
      console.error("REPLICATE_API_TOKEN not configured");
      return new Response(
        JSON.stringify({ error: "Video service not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get user from auth header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.error("Auth error:", authError);
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get user profile
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("credits_remaining, subscription_tier")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      console.error("Profile error:", profileError);
      return new Response(JSON.stringify({ error: "Profile not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check if user can generate video
    if (profile.subscription_tier === "pro") {
      // Pro user - check monthly quota
      const { data: quotaData, error: quotaError } = await supabase
        .rpc("can_pro_user_generate_video", { user_uuid: user.id });

      if (quotaError) {
        console.error("Quota check error:", quotaError);
        return new Response(
          JSON.stringify({ error: "Failed to check quota" }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const quotaStatus = quotaData?.[0] as ProQuotaStatus | undefined;

      if (quotaStatus && !quotaStatus.can_generate) {
        const resetDate = new Date(quotaStatus.resets_at).toLocaleDateString("en-US", {
          month: "long",
          day: "numeric",
        });

        return new Response(
          JSON.stringify({
            error: "Monthly limit reached",
            code: "QUOTA_EXCEEDED",
            details: {
              videosUsed: quotaStatus.videos_used,
              quotaLimit: quotaStatus.quota_limit,
              videosRemaining: quotaStatus.videos_remaining,
              resetsAt: quotaStatus.resets_at,
              message: `You've used all ${quotaStatus.quota_limit} videos for this month. Your quota resets on ${resetDate}.`
            }
          }),
          {
            status: 429, // Too Many Requests
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      console.log(`Pro user quota: ${quotaStatus?.videos_used ?? 0}/${quotaStatus?.quota_limit ?? 30} used`);
    } else {
      // Free user - use existing credits system
      if (profile.credits_remaining <= 0) {
        return new Response(
          JSON.stringify({
            error: "No credits remaining",
            code: "NO_CREDITS",
            message: "No credits remaining. Please upgrade to Pro."
          }),
          {
            status: 402, // Payment Required
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    // Parse request body
    const { dream_id, prompt }: GenerateVideoRequest = await req.json();

    if (!dream_id || !prompt) {
      return new Response(
        JSON.stringify({ error: "Missing dream_id or prompt" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify dream belongs to user
    const { data: dream, error: dreamError } = await supabase
      .from("dreams")
      .select("id")
      .eq("id", dream_id)
      .eq("user_id", user.id)
      .single();

    if (dreamError || !dream) {
      console.error("Dream error:", dreamError);
      return new Response(JSON.stringify({ error: "Dream not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create video job record first
    const { data: job, error: jobError } = await supabase
      .from("video_jobs")
      .insert({
        dream_id: dream_id,
        user_id: user.id,
        status: "processing",
      })
      .select()
      .single();

    if (jobError) {
      console.error("Error creating job:", jobError);
      return new Response(
        JSON.stringify({ error: "Failed to create video job" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Call Replicate API to start video generation BEFORE deducting credits
    // This prevents losing credits on API failures
    console.log("Starting Replicate prediction for prompt:", prompt);

    const replicateResponse = await fetch(
      "https://api.replicate.com/v1/predictions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${replicateToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          // Kling v2.5 Turbo Pro - 5s video generation
          version: "939cd1851c5b112f284681b57ee9b0f36d0f913ba97de5845a7eef92d52837df",
          input: {
            prompt: `Cinematic, dreamlike, ethereal atmosphere: ${prompt}`,
            duration: 5,
            aspect_ratio: "16:9",
            negative_prompt: "blurry, low quality, distorted, ugly, bad anatomy"
          }
        }),
      }
    );

    if (!replicateResponse.ok) {
      let errorText = "Unknown error";
      try {
        errorText = await replicateResponse.text();
      } catch (e) {
        errorText = `HTTP ${replicateResponse.status}`;
      }

      // Parse JSON error if possible for cleaner message
      let errorMessage = errorText;
      try {
        const errorJson = JSON.parse(errorText);
        errorMessage = errorJson.detail || errorJson.title || errorJson.error || errorText;
      } catch {
        // Keep raw text
      }

      console.error("Replicate API error:", replicateResponse.status, errorMessage);

      // Update job status to failed (no credit was deducted yet)
      const { error: updateError } = await supabase
        .from("video_jobs")
        .update({ status: "failed", error_message: errorMessage.substring(0, 1000) })
        .eq("id", job.id);

      if (updateError) {
        console.error("Failed to update job with error:", updateError);
      }

      // Return appropriate status code based on Replicate error
      const statusCode = replicateResponse.status === 402 ? 402 : 500;
      return new Response(
        JSON.stringify({
          error: errorMessage,
          code: replicateResponse.status === 402 ? "BILLING_REQUIRED" : "GENERATION_FAILED"
        }),
        {
          status: statusCode,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const prediction: ReplicatePrediction = await replicateResponse.json();
    console.log("Prediction started:", prediction.id);

    // NOW deduct credit AFTER successful API call (atomic operation)
    if (profile.subscription_tier === "free") {
      // Use atomic decrement to prevent race conditions
      const { error: creditError } = await supabase.rpc("decrement_credits", {
        user_uuid: user.id
      });

      if (creditError) {
        console.error("Credit deduction error:", creditError);
        // Cancel the prediction if we can't deduct credits
        try {
          await fetch(
            `https://api.replicate.com/v1/predictions/${prediction.id}/cancel`,
            {
              method: "POST",
              headers: { Authorization: `Bearer ${replicateToken}` },
            }
          );
        } catch (cancelError) {
          console.error("Failed to cancel prediction:", cancelError);
        }

        await supabase
          .from("video_jobs")
          .update({ status: "failed", error_message: "Failed to process credits" })
          .eq("id", job.id);

        return new Response(
          JSON.stringify({ error: "Failed to process credits" }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    // Update job with replicate ID and set status to pending
    await supabase
      .from("video_jobs")
      .update({
        replicate_id: prediction.id,
        status: "pending"
      })
      .eq("id", job.id);

    // Return immediately - client will poll for status
    // The check-video-status function will handle completion
    return new Response(
      JSON.stringify({
        jobId: prediction.id  // Return the replicate ID for polling
      }),
      {
        status: 202,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: `Internal server error: ${error.message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
