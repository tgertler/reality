import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type RevenueCatEvent = {
  type?: string;
  app_user_id?: string;
  expiration_at_ms?: number | string | null;
  expires_date_ms?: number | string | null;
};

type RevenueCatWebhookBody = {
  event?: RevenueCatEvent;
};

function getBearerToken(authHeader: string | null): string | null {
  if (!authHeader) return null;
  const [scheme, token] = authHeader.split(" ");
  if (!scheme || !token) return null;
  if (scheme.toLowerCase() !== "bearer") return null;
  return token;
}

function parseExpiryIso(event: RevenueCatEvent): string | null {
  const raw = event.expiration_at_ms ?? event.expires_date_ms;
  if (raw == null) return null;
  const asNumber = Number(raw);
  if (!Number.isFinite(asNumber)) return null;
  return new Date(asNumber).toISOString();
}

function mapPremiumStatus(eventType: string): boolean | null {
  const normalized = eventType.toUpperCase();
  if (["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "NON_RENEWING_PURCHASE", "SUBSCRIPTION_EXTENDED"].includes(normalized)) {
    return true;
  }
  if (["CANCELLATION", "EXPIRATION", "BILLING_ISSUE"]
    .includes(normalized)) {
    return false;
  }
  return null;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const expectedSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? "";
  const providedSecret = getBearerToken(req.headers.get("authorization"));

  if (!expectedSecret || !providedSecret || providedSecret !== expectedSecret) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response("Missing Supabase configuration", { status: 500 });
  }

  let body: RevenueCatWebhookBody;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const event = body.event;
  const eventType = event?.type?.toString() ?? "";
  const appUserId = event?.app_user_id?.toString() ?? "";

  if (!event || !eventType || !appUserId) {
    return new Response("Missing event payload", { status: 400 });
  }

  const premiumStatus = mapPremiumStatus(eventType);
  if (premiumStatus == null) {
    return new Response(JSON.stringify({ skipped: true, reason: "event_not_mapped", eventType }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  }

  const expiresAt = premiumStatus ? parseExpiryIso(event) : null;

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { error } = await supabase.rpc("fn_set_premium_status", {
    p_user_id: appUserId,
    p_is_premium: premiumStatus,
    p_expires_at: expiresAt,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify({
      ok: true,
      userId: appUserId,
      eventType,
      isPremium: premiumStatus,
      premiumUntil: expiresAt,
    }),
    {
      status: 200,
      headers: { "content-type": "application/json" },
    },
  );
});
