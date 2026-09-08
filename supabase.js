import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

// এখানে তোমার Supabase information বসাও
const SUPABASE_URL = "YOUR_SUPABASE_URL";

const SUPABASE_KEY = "YOUR_SUPABASE_PUBLISHABLE_KEY";

export const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_KEY
);
