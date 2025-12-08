// Dream Journal - Check Video Status Edge Function
// This function checks pending video jobs with Replicate and completes them

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CheckStatusRequest {
  replicate_id: string;
}

interface ReplicatePrediction {
  id: string;
  status: string;
  output?: string | string[];
  error?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const replicateToken = Deno.env.get("REPLICATE_API_TOKEN");

    if (!replicateToken) {
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
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Parse request body
    const { replicate_id }: CheckStatusRequest = await req.json();

    if (!replicate_id) {
      return new Response(
        JSON.stringify({ error: "Missing replicate_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get the job from database
    const { data: job, error: jobError } = await supabase
      .from("video_jobs")
      .select("*")
      .eq("replicate_id", replicate_id)
      .eq("user_id", user.id)
      .single();

    if (jobError || !job) {
      return new Response(JSON.stringify({ error: "Job not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // If already completed or failed, return current status
    if (job.status === "completed" || job.status === "failed") {
      return new Response(
        JSON.stringify({
          status: job.status,
          videoPath: job.video_path,
          videoUrl: job.video_url
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check status with Replicate
    const replicateResponse = await fetch(
      `https://api.replicate.com/v1/predictions/${replicate_id}`,
      {
        headers: {
          Authorization: `Bearer ${replicateToken}`,
        },
      }
    );

    if (!replicateResponse.ok) {
      return new Response(
        JSON.stringify({ error: "Failed to check Replicate status" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const prediction: ReplicatePrediction = await replicateResponse.json();
    console.log("Prediction status:", prediction.id, prediction.status);

    // Handle different statuses
    if (prediction.status === "succeeded") {
      // Get video URL from output
      const videoUrl = Array.isArray(prediction.output)
        ? prediction.output[0]
        : prediction.output;

      console.log("Video generated:", videoUrl);

      // Download and save video to Supabase Storage
      let videoPath: string | null = null;
      try {
        const videoResponse = await fetch(videoUrl);
        const videoBlob = await videoResponse.blob();
        const videoBuffer = await videoBlob.arrayBuffer();

        videoPath = `${user.id}/${job.id}.mp4`;

        const { error: uploadError } = await supabase.storage
          .from("dream-videos")
          .upload(videoPath, videoBuffer, {
            contentType: "video/mp4",
            upsert: true,
          });

        if (uploadError) {
          console.error("Upload error:", uploadError);
        } else {
          console.log("Video saved to storage:", videoPath);
        }
      } catch (downloadError) {
        console.error("Error downloading video:", downloadError);
      }

      // Update job status
      await supabase
        .from("video_jobs")
        .update({
          status: "completed",
          video_path: videoPath,
          video_url: videoUrl,
          completed_at: new Date().toISOString()
        })
        .eq("id", job.id);

      // Update dream with video path
      if (videoPath) {
        await supabase
          .from("dreams")
          .update({ video_path: videoPath })
          .eq("id", job.dream_id);
      }

      return new Response(
        JSON.stringify({
          status: "completed",
          videoPath: videoPath,
          videoUrl: videoUrl
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );

    } else if (prediction.status === "failed") {
      // Update job as failed
      await supabase
        .from("video_jobs")
        .update({
          status: "failed",
          error_message: prediction.error || "Video generation failed"
        })
        .eq("id", job.id);

      // Refund credit if free tier
      const { data: profile } = await supabase
        .from("profiles")
        .select("credits_remaining, subscription_tier")
        .eq("id", user.id)
        .single();

      if (profile && profile.subscription_tier === "free") {
        await supabase
          .from("profiles")
          .update({ credits_remaining: profile.credits_remaining + 1 })
          .eq("id", user.id);
      }

      return new Response(
        JSON.stringify({
          status: "failed",
          error: prediction.error || "Video generation failed"
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );

    } else {
      // Still processing
      return new Response(
        JSON.stringify({
          status: prediction.status === "starting" ? "pending" : "processing"
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

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
