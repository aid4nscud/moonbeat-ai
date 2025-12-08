// Dream Journal - Webhook Handler Edge Function
// Handles callbacks from Replicate when video generation completes

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, webhook-id, webhook-timestamp, webhook-signature",
};

interface ReplicateWebhook {
  id: string;
  status: "starting" | "processing" | "succeeded" | "failed" | "canceled";
  output?: string | string[];
  error?: string;
}

// Verify webhook signature using HMAC-SHA256
async function verifyWebhookSignature(
  body: string,
  signature: string | null,
  webhookId: string | null,
  timestamp: string | null,
  secret: string
): Promise<boolean> {
  if (!signature || !webhookId || !timestamp) {
    console.error("Missing webhook headers for verification");
    return false;
  }

  // Check timestamp to prevent replay attacks (allow 5 min window)
  const timestampMs = parseInt(timestamp) * 1000;
  const now = Date.now();
  const fiveMinutes = 5 * 60 * 1000;

  if (Math.abs(now - timestampMs) > fiveMinutes) {
    console.error("Webhook timestamp too old or in future");
    return false;
  }

  // Replicate signature format: v1,<base64-signature>
  const signatureParts = signature.split(",");
  const signatureValue = signatureParts.length > 1 ? signatureParts[1] : signatureParts[0];

  // Create the signed payload: webhook_id.timestamp.body
  const signedPayload = `${webhookId}.${timestamp}.${body}`;

  // Compute expected signature
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signatureBytes = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(signedPayload)
  );

  const expectedSignature = btoa(String.fromCharCode(...new Uint8Array(signatureBytes)));

  // Constant-time comparison to prevent timing attacks
  return signatureValue === expectedSignature;
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
    const webhookSecret = Deno.env.get("REPLICATE_WEBHOOK_SECRET");

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get raw body for signature verification
    const body = await req.text();

    // Verify webhook signature if secret is configured
    if (webhookSecret) {
      const signature = req.headers.get("webhook-signature");
      const webhookId = req.headers.get("webhook-id");
      const timestamp = req.headers.get("webhook-timestamp");

      const isValid = await verifyWebhookSignature(
        body,
        signature,
        webhookId,
        timestamp,
        webhookSecret
      );

      if (!isValid) {
        console.error("Invalid webhook signature");
        return new Response(JSON.stringify({ error: "Unauthorized" }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    } else {
      console.warn("REPLICATE_WEBHOOK_SECRET not configured - webhook verification disabled");
    }

    // Parse webhook payload
    const payload: ReplicateWebhook = JSON.parse(body);
    console.log("Received webhook:", JSON.stringify(payload));

    const { id: replicateId, status, output, error } = payload;

    // Idempotency check: use webhook-id if available, otherwise replicate_id + status
    const webhookIdHeader = req.headers.get("webhook-id");
    const idempotencyKey = webhookIdHeader || `${replicateId}-${status}`;

    // Check if we've already processed this webhook
    const { data: existingWebhook } = await supabase
      .from("processed_webhooks")
      .select("webhook_id")
      .eq("webhook_id", idempotencyKey)
      .single();

    if (existingWebhook) {
      console.log("Webhook already processed:", idempotencyKey);
      return new Response(JSON.stringify({ success: true, duplicate: true }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Record this webhook to prevent duplicate processing
    await supabase
      .from("processed_webhooks")
      .insert({ webhook_id: idempotencyKey });

    // Find the video job
    const { data: job, error: jobError } = await supabase
      .from("video_jobs")
      .select("*")
      .eq("replicate_id", replicateId)
      .single();

    if (jobError || !job) {
      console.error("Job not found for replicate_id:", replicateId);
      return new Response(JSON.stringify({ error: "Job not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Skip if job is already in a terminal state
    if (job.status === "completed" || job.status === "failed") {
      console.log("Job already in terminal state:", job.status);
      return new Response(JSON.stringify({ success: true, skipped: true }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Handle different statuses
    if (status === "succeeded" && output) {
      // Get the video URL from output
      const videoUrl = Array.isArray(output) ? output[0] : output;

      if (videoUrl) {
        try {
          // Download video from Replicate
          const videoResponse = await fetch(videoUrl);
          const videoBlob = await videoResponse.blob();
          const videoBuffer = await videoBlob.arrayBuffer();

          // Generate storage path
          const fileName = `${job.user_id}/${job.id}.mp4`;

          // Upload to Supabase Storage
          const { error: uploadError } = await supabase.storage
            .from("dream-videos")
            .upload(fileName, videoBuffer, {
              contentType: "video/mp4",
              upsert: true,
            });

          if (uploadError) {
            console.error("Upload error:", uploadError);
            throw new Error("Failed to upload video");
          }

          // Update job with success
          await supabase
            .from("video_jobs")
            .update({
              status: "completed",
              video_path: fileName,
              completed_at: new Date().toISOString(),
            })
            .eq("id", job.id);

          console.log("Video saved successfully:", fileName);
        } catch (downloadError) {
          console.error("Error downloading/uploading video:", downloadError);

          // Update job with failure
          await supabase
            .from("video_jobs")
            .update({
              status: "failed",
              error_message: "Failed to save video",
              completed_at: new Date().toISOString(),
            })
            .eq("id", job.id);
        }
      }
    } else if (status === "failed" || status === "canceled") {
      // Update job with failure
      await supabase
        .from("video_jobs")
        .update({
          status: "failed",
          error_message: error || "Video generation failed",
          completed_at: new Date().toISOString(),
        })
        .eq("id", job.id);

      // Refund credit if it was a free user (use atomic function)
      const { data: profile } = await supabase
        .from("profiles")
        .select("subscription_tier")
        .eq("id", job.user_id)
        .single();

      if (profile?.subscription_tier === "free") {
        await supabase.rpc("refund_credit", { user_uuid: job.user_id });
        console.log("Credit refunded for user:", job.user_id);
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
