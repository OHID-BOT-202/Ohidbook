import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

// এখানে তোমার Supabase information বসাও
const SUPABASE_URL = "https://wbevujnminvgvwkrkysa.supabase.co";

const SUPABASE_KEY = "sb_publishable_3D-903R2J0_KJA7LIiyYeQ_kYmIKq_c";

export const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_KEY
);
