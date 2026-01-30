"use client";

import { useQuery } from "@tanstack/react-query";

import { useSupabase } from "@/lib/queries/supabase";
import type { Database } from "@/types/supabase";

type ProfileRow = Database["public"]["Tables"]["profiles"]["Row"];

export function useProfile() {
  const supabase = useSupabase();

  return useQuery({
    queryKey: ["me", "profile"],
    queryFn: async () => {
      const { data: auth } = await supabase.auth.getUser();
      const user = auth.user;
      if (!user) return null;

      const { data, error } = await supabase.from("profiles").select("*").eq("id", user.id).maybeSingle();
      if (error) throw error;
      return (data as ProfileRow | null) ?? null;
    },
  });
}
