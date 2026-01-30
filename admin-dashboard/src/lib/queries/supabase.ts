"use client";

import * as React from "react";

import { createSupabaseBrowserClient } from "@/lib/supabase/client";

export function useSupabase() {
  return React.useMemo(() => createSupabaseBrowserClient(), []);
}

