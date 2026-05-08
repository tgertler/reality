import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// --------------------
// Supabase Client
// --------------------
const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
// --------------------
// Firebase Credentials
// --------------------
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID");
const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL");
const FIREBASE_PRIVATE_KEY = Deno.env.get("FIREBASE_PRIVATE_KEY").replace(/\\n/g, "\n");
// --------------------
// Utils: Base64URL
// --------------------
function base64UrlEncode(input) {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  return btoa(String.fromCharCode(...bytes)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}
// --------------------
// JWT Signierung
// --------------------
async function createSignedJWT() {
  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: "RS256",
    typ: "JWT"
  };
  const payload = {
    iss: FIREBASE_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 60 * 60
  };
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const unsignedToken = `${encodedHeader}.${encodedPayload}`;
  // Import Private Key
  const key = await crypto.subtle.importKey("pkcs8", pemToBuffer(FIREBASE_PRIVATE_KEY), {
    name: "RSASSA-PKCS1-v1_5",
    hash: "SHA-256"
  }, false, [
    "sign"
  ]);
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsignedToken));
  return `${unsignedToken}.${base64UrlEncode(new Uint8Array(signature))}`;
}
function pemToBuffer(pem) {
  const b64 = pem.replace("-----BEGIN PRIVATE KEY-----", "").replace("-----END PRIVATE KEY-----", "").replace(/\s+/g, "");
  const binary = atob(b64);
  const buffer = new Uint8Array(binary.length);
  for(let i = 0; i < binary.length; i++){
    buffer[i] = binary.charCodeAt(i);
  }
  return buffer.buffer;
}
// --------------------
// OAuth Token holen
// --------------------
async function getFirebaseAccessToken() {
  const jwt = await createSignedJWT();
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt
    })
  });
  const json = await res.json();
  if (!res.ok) {
    console.error("OAuth error", json);
    throw new Error("Failed to get Firebase access token");
  }
  return json.access_token;
}
function humanTime(iso) {
  if (typeof iso !== "string") return undefined;
  return iso.split(/[+Z]/)[0];
}
function getPushContent(type, payload) {
  switch(type){
    case "PREMIERE_ONE_DAY_BEFORE":
      {
        const showTitle = typeof payload?.show_title === "string" ? payload.show_title : null;
        const episodeNumber = typeof payload?.episode_number === "number" ? payload.episode_number : null;
        const title = "🎬 Premiere morgen";
        const bodyParts = [];
        if (showTitle) bodyParts.push(showTitle);
        if (episodeNumber !== null) bodyParts.push(`Episode ${episodeNumber}`);
        const body = bodyParts.length > 0 ? bodyParts.join(" · ") : typeof payload?.description === "string" ? payload.description : "Morgen gibts eine neue Show!";
        return {
          title,
          body
        };
      }
    case "DAILY_DIGEST":
      {
        const events = Array.isArray(payload?.events) ? payload.events : [];
        const title = "📅 Daily-Update";
        const titles = events.map((e)=>typeof e?.title === "string" ? e.title : null).filter(Boolean);
        const body = titles.length > 0 ? titles.join(" · ") : typeof payload?.message === "string" ? payload.message : "Heute nichts los";
        return {
          title,
          body
        };
      }
    case "DAILY_DIGEST_FAVORITE":
      {
        const events = Array.isArray(payload?.events) ? payload.events : [];
        const title = "⭐ Dein Trash-Tag";
        const titles = events.map((e)=>typeof e?.title === "string" ? e.title : null).filter(Boolean);
        const body = titles.length > 0 ? titles.join(" · ") : typeof payload?.message === "string" ? payload.message : "Heute nichts los";
        return {
          title,
          body
        };
      }
    case "CALENDAR_EVENT_REMINDER":
      {
        const showTitle = typeof payload?.show_title === "string" ? payload.show_title : "dein Event";
        const startDatetime = typeof payload?.start_datetime === "string" ? payload.start_datetime : undefined;
        // optional: nutze "YYYY-MM-DDTHH:MM" -> "YYYY-MM-DDTHH:MM"
        const startHuman = humanTime(startDatetime);
        const title = "⏰ Kalender-Erinnerung";
        const body = startHuman ? `${showTitle} beginnt um ${startHuman}` : `${showTitle} beginnt bald`;
        return {
          title,
          body
        };
      }
    default:
      return {
        title: typeof payload?.title === "string" ? payload.title : "",
        body: typeof payload?.body === "string" ? payload.body : ""
      };
  }
}
// --------------------
// Edge Function Handler
// --------------------
serve(async ()=>{
  // 1. Pending Notifications
  const { data: notifications } = await supabase.from("notification_outbox").select("*").eq("status", "pending").limit(25);
  if (!notifications || notifications.length === 0) {
    return new Response("No notifications");
  }
  const accessToken = await getFirebaseAccessToken();
  for (const n of notifications){
    // 2. Devices
    const { data: devices } = await supabase.from("user_devices").select("fcm_token").eq("user_id", n.user_id).eq("is_active", true);
    const { title, body } = getPushContent(n.type, n.payload);
    if (!devices || devices.length === 0) continue;
    for (const d of devices){
      await fetch(`https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: {
            token: d.fcm_token,
            notification: {
              title,
              body
            },
            data: {
              type: n.type,
              calendar_event_id: n.payload.calendar_event_id,
              show_id: n.payload.show_id
            }
          }
        })
      });
    }
    // 3. Mark as sent
    await supabase.from("notification_outbox").update({
      status: "sent",
      sent_at: new Date().toISOString()
    }).eq("id", n.id);
  }
  return new Response("Push notifications sent ✅");
});
