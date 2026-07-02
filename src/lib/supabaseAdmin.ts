import "server-only";
import { createClient } from "@supabase/supabase-js";

// Server-side Supabase client, used only from Route Handlers / Server
// Components (never imported into client components).
//
// This is an internal tool with no separate end-user auth system in scope
// for V1 (see brief). Rather than wire in a service-role secret key (which
// would need to be typed in by hand and kept out of source control), we use
// the anon/publishable key plus explicit RLS policies on product_sheets and
// the two storage buckets that grant the `anon` role read/write access. If
// user auth is introduced later, tighten those policies and switch this to
// a service-role key kept in Vercel's encrypted env vars.
let cached: ReturnType<typeof createClient> | null = null;

export function supabaseAdmin() {
  if (cached) return cached;

  const url = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables.");
  }

  cached = createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return cached;
}

export const PRODUCT_IMAGES_BUCKET = "product-images";
export const PRODUCT_PDFS_BUCKET = "product-sheet-pdfs";
