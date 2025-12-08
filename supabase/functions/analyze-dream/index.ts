// Dream Journal - AI Dream Interpretation Edge Function
// Uses Replicate LLM to generate personalized dream insights

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface AnalyzeDreamRequest {
  dream_id: string;
}

interface ReplicatePrediction {
  id: string;
  status: string;
  output?: string | string[];
  error?: string;
}

// Poll for prediction completion
async function pollPrediction(
  predictionId: string,
  token: string,
  maxAttempts = 30
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

    // Wait 1 second before next poll
    await new Promise((resolve) => setTimeout(resolve, 1000));
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
        JSON.stringify({ error: "AI service not configured" }),
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

    // Check if user has Pro subscription
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("subscription_tier")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      console.error("Profile error:", profileError);
      return new Response(JSON.stringify({ error: "Profile not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (profile.subscription_tier !== "pro") {
      return new Response(
        JSON.stringify({
          error: "Pro subscription required",
          code: "REQUIRES_PRO",
          message: "AI Dream Interpretation is a Pro feature. Upgrade to unlock personalized insights."
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const { dream_id }: AnalyzeDreamRequest = await req.json();

    if (!dream_id) {
      return new Response(
        JSON.stringify({ error: "Missing dream_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get the dream with all details
    const { data: dream, error: dreamError } = await supabase
      .from("dreams")
      .select("id, transcript, themes, emotions, title, created_at, interpretation")
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

    // Check if interpretation already exists
    if (dream.interpretation) {
      return new Response(
        JSON.stringify({
          interpretation: dream.interpretation,
          cached: true
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get recent dreams for context (last 5)
    const { data: recentDreams } = await supabase
      .from("dreams")
      .select("themes, emotions, title")
      .eq("user_id", user.id)
      .neq("id", dream_id)
      .order("created_at", { ascending: false })
      .limit(5);

    // Build context from recent dreams
    const recentContext = recentDreams?.length
      ? `Recent dream themes: ${recentDreams.flatMap(d => d.themes || []).slice(0, 10).join(", ")}`
      : "";

    // Create the prompt for dream interpretation
    const dreamDate = new Date(dream.created_at).toLocaleDateString("en-US", {
      weekday: "long",
      month: "long",
      day: "numeric",
    });

    const systemPrompt = `You are a compassionate and insightful dream analyst with deep knowledge of dream symbolism, psychology, and personal growth. Your role is to help people understand their dreams in a meaningful way.

When analyzing dreams:
- Be warm, supportive, and non-judgmental
- Focus on the emotional core of the dream
- Identify key symbols and their potential meanings
- Connect themes to the dreamer's life journey
- Offer actionable insights for personal growth
- Keep interpretations grounded and practical
- Use a conversational, friendly tone

Format your response in these sections:
1. **Overview**: A 2-3 sentence summary of the dream's core message
2. **Key Symbols**: The most significant elements and what they might represent
3. **Emotional Insights**: What the dream reveals about the dreamer's inner world
4. **Life Connections**: How this dream might relate to waking life
5. **Reflection Questions**: 2-3 thoughtful questions for the dreamer to consider`;

    const userPrompt = `Please interpret this dream recorded on ${dreamDate}:

**Dream Description:**
${dream.transcript}

**Detected Themes:** ${dream.themes?.join(", ") || "None detected"}
**Detected Emotions:** ${dream.emotions?.join(", ") || "None detected"}

${recentContext}

Provide a thoughtful, personalized interpretation that helps the dreamer understand what their subconscious might be communicating.`;

    console.log("Calling Replicate LLM for dream interpretation...");

    // Call Replicate API with Llama 3.1 70B
    const replicateResponse = await fetch(
      "https://api.replicate.com/v1/predictions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${replicateToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          // Meta Llama 3.1 70B Instruct
          version: "a52e56fee2269a78c9279800ec88898cecb6c8f1df22a6c3117f1d5c6e2d6b1d",
          input: {
            prompt: userPrompt,
            system_prompt: systemPrompt,
            max_tokens: 1500,
            temperature: 0.7,
            top_p: 0.9,
          }
        }),
      }
    );

    if (!replicateResponse.ok) {
      const errorText = await replicateResponse.text();
      console.error("Replicate API error:", replicateResponse.status, errorText);
      return new Response(
        JSON.stringify({ error: "AI interpretation failed" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const prediction: ReplicatePrediction = await replicateResponse.json();
    console.log("Prediction started:", prediction.id);

    // Poll for completion
    const completedPrediction = await pollPrediction(prediction.id, replicateToken);

    if (completedPrediction.status === "failed") {
      console.error("Prediction failed:", completedPrediction.error);
      return new Response(
        JSON.stringify({ error: "AI interpretation failed" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Extract the interpretation text
    let interpretation = "";
    if (Array.isArray(completedPrediction.output)) {
      interpretation = completedPrediction.output.join("");
    } else if (typeof completedPrediction.output === "string") {
      interpretation = completedPrediction.output;
    }

    if (!interpretation) {
      return new Response(
        JSON.stringify({ error: "No interpretation generated" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Save interpretation to database
    const { error: updateError } = await supabase
      .from("dreams")
      .update({ interpretation })
      .eq("id", dream_id);

    if (updateError) {
      console.error("Error saving interpretation:", updateError);
      // Still return the interpretation even if save fails
    }

    console.log("Dream interpretation completed successfully");

    return new Response(
      JSON.stringify({
        interpretation,
        cached: false
      }),
      {
        status: 200,
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
