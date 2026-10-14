import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

async function sha256(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), b => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== "POST") return response(405, { ok: false, error: "method_not_allowed" });

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return response(503, { ok: false, error: "feedback_unavailable" });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return response(400, { ok: false, error: "invalid_json" });
  }
  const category = body.category;
  const rating = body.rating === "" || body.rating == null ? null : Number(body.rating);
  const message = typeof body.message === "string" ? body.message.trim() : "";
  const contactEmail = typeof body.contact_email === "string" ? body.contact_email.trim() : "";
  const pagePath = typeof body.page_path === "string" ? body.page_path : "";
  const honeypot = typeof body.website === "string" ? body.website.trim() : "";

  // Bots that fill the hidden honeypot receive a generic success without writing.
  if (honeypot) return response(200, { ok: true });
  if (!["question", "bug", "suggestion", "content", "accessibility", "other"].includes(String(category))) {
    return response(400, { ok: false, error: "invalid_category" });
  }
  if (rating !== null && (!Number.isInteger(rating) || rating < 1 || rating > 5)) {
    return response(400, { ok: false, error: "invalid_rating" });
  }
  if (message.length < 5 || message.length > 2000) return response(400, { ok: false, error: "invalid_message" });
  if (contactEmail && (contactEmail.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(contactEmail))) {
    return response(400, { ok: false, error: "invalid_email" });
  }
  if (pagePath && (pagePath.length > 300 || !pagePath.startsWith("/") || pagePath.startsWith("//"))) {
    return response(400, { ok: false, error: "invalid_page" });
  }

  let userId: string | null = null;
  const auth = req.headers.get("authorization");
  if (auth) {
    const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { apikey: anonKey, Authorization: auth },
    });
    if (!userResponse.ok) return response(401, { ok: false, error: "invalid_session" });
    const user = await userResponse.json();
    if (typeof user?.id !== "string") return response(401, { ok: false, error: "invalid_session" });
    userId = user.id;
  }

  // Prefer proxy-provided IP headers; never store the raw address.
  const ip = req.headers.get("cf-connecting-ip")
    || req.headers.get("x-real-ip")
    || req.headers.get("x-forwarded-for")?.split(",")[0]?.trim()
    || "unknown";
  const ipHash = await sha256(`${serviceKey}:ug-feedback:${ip}`);

  const dbResponse = await fetch(`${supabaseUrl}/rest/v1/rpc/submit_site_feedback`, {
    method: "POST",
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      p_ip_hash: ipHash,
      p_user_id: userId,
      p_category: category,
      p_rating: rating,
      p_message: message,
      p_contact_email: contactEmail || null,
      p_page_path: pagePath || null,
    }),
  });
  if (!dbResponse.ok) return response(503, { ok: false, error: "feedback_unavailable" });
  const result = await dbResponse.json().catch(() => null);
  if (result?.reason === "rate_limited") return response(429, { ok: false, error: "rate_limited" });
  if (!result?.ok) return response(400, { ok: false, error: "invalid_feedback" });
  return response(200, { ok: true });
});
