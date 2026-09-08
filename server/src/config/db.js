import { createClient } from "@supabase/supabase-js";
import { config } from "./env.js";

const supabaseUrl = config.supabaseUrl;
const supabaseKey = config.supabaseServiceKey || config.supabaseAnonKey;

export const isDatabaseConnected = Boolean(supabaseUrl && supabaseKey);

// Supabase client instance
export const supabase = isDatabaseConnected
  ? createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    })
  : null;

if (isDatabaseConnected) {
  console.log("[Database] Connected to live Supabase project.");
} else {
  console.log("[Database] Supabase keys not set in .env. Ready for credentials.");
}

