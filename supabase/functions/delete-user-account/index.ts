// Supabase Edge Function: delete-user-account
// Purpose: Allow a logged-in user (Flutter) to delete *their own* account.
// Expects JSON body: { "userId": "<uuid>" } (optional; will default to auth.uid())
// Auth: Requires Authorization: Bearer <JWT>
import process from "node:process";
import { createClient } from "npm:@supabase/supabase-js@2.48.1";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS"
};
Deno.serve(async (req)=>{
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({
      error: "Method not allowed"
    }), {
      status: 405,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
  const authHeader = req.headers.get("authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return new Response(JSON.stringify({
      error: "Missing bearer token"
    }), {
      status: 401,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const anonKey = process.env.SUPABASE_ANON_KEY;
  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    return new Response(JSON.stringify({
      error: "Missing SUPABASE env vars"
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
  const body = await req.json().catch(()=>null);
  // 1) Verify caller identity using anon key + user's JWT
  const supabaseAuthed = createClient(supabaseUrl, anonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false
    },
    global: {
      headers: {
        Authorization: authHeader
      }
    }
  });
  const { data: { user }, error: userErr } = await supabaseAuthed.auth.getUser();
  if (userErr || !user) {
    return new Response(JSON.stringify({
      error: "Invalid or expired token"
    }), {
      status: 401,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
  const authUserId = user.id;
  const requestedUserId = body?.userId ?? authUserId;
  // 2) Enforce: user can delete only their own account
  if (requestedUserId !== authUserId) {
    return new Response(JSON.stringify({
      error: "Forbidden: can only delete your own account"
    }), {
      status: 403,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
  // 3) Delete via Admin API (service role)
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false
    }
  });
  const { data, error } = await supabaseAdmin.auth.admin.deleteUser(authUserId);
  if (error) {
    return new Response(JSON.stringify({
      error: "Failed to delete user",
      details: error.message ?? String(error)
    }), {
      status: 400,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
  return new Response(JSON.stringify({
    ok: true,
    userId: authUserId,
    data
  }), {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json"
    }
  });
});
