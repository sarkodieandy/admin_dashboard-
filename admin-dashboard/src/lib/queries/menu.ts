"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { useProfile } from "@/lib/queries/profile";
import { useSupabase } from "@/lib/queries/supabase";
import type { Database } from "@/types/supabase";

type CategoryRow = Database["public"]["Tables"]["categories"]["Row"];
type MenuItemRow = Database["public"]["Tables"]["menu_items"]["Row"];

export function useCategories() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["menu", "categories"],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const { data, error } = await supabase.from("categories").select("*").order("sort_order", { ascending: true });
      if (error) throw error;
      return (data as CategoryRow[]) ?? [];
    },
  });
}

export function useMenuItems() {
  const supabase = useSupabase();
  const profile = useProfile();

  return useQuery({
    queryKey: ["menu", "items"],
    enabled: !!profile.data?.id,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("menu_items")
        .select("id,category_id,name,description,base_price,image_url,spice_level,is_active,is_sold_out,created_at,updated_at,categories(name)")
        .order("created_at", { ascending: false })
        .limit(200);
      if (error) throw error;
      type Row = MenuItemRow & { categories: { name: string } | null };
      return ((data as Row[]) ?? []).map((row) => ({
        ...(row as MenuItemRow),
        category_name: row.categories?.name ?? null,
      }));
    },
  });
}

export function useUploadMenuImage() {
  const supabase = useSupabase();

  return useMutation({
    mutationFn: async (file: File) => {
      const path = `menu/${Date.now()}-${file.name}`;
      const { error } = await supabase.storage.from("menu-images").upload(path, file, { upsert: false });
      if (error) throw error;
      const { data } = supabase.storage.from("menu-images").getPublicUrl(path);
      return data.publicUrl;
    },
  });
}

export function useUpsertMenuItem() {
  const supabase = useSupabase();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async (payload: Database["public"]["Tables"]["menu_items"]["Insert"]) => {
      const { error } = await supabase.from("menu_items").insert(payload);
      if (error) throw error;
      return true;
    },
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: ["menu", "items"] });
    },
  });
}

export function useUpdateCategoryOrder() {
  const supabase = useSupabase();
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, direction }: { id: string; direction: "up" | "down" }) => {
      const categories = (qc.getQueryData<CategoryRow[]>(["menu", "categories"]) ?? []).slice();
      const idx = categories.findIndex((c) => c.id === id);
      if (idx < 0) return;
      const swapWith = direction === "up" ? idx - 1 : idx + 1;
      if (swapWith < 0 || swapWith >= categories.length) return;

      const a = categories[idx]!;
      const b = categories[swapWith]!;

      const { error: e1 } = await supabase.from("categories").update({ sort_order: b.sort_order }).eq("id", a.id);
      if (e1) throw e1;
      const { error: e2 } = await supabase.from("categories").update({ sort_order: a.sort_order }).eq("id", b.id);
      if (e2) throw e2;
    },
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: ["menu", "categories"] });
    },
  });
}
