import { getClient } from "./auth.js";

const supabase = getClient();

export const MENU_IMAGES_BUCKET = "menu-images";

function normalizePath(path) {
  if (!path) return null;
  let p = String(path).trim();
  if (!p) return null;

  // Already a full URL.
  if (/^https?:\/\//i.test(p)) return { kind: "url", value: p };

  // Handle stored public URLs where the DB saved the full public URL.
  // Convert it back to bucket+object path for consistent handling.
  const marker = "/storage/v1/object/public/";
  const idx = p.indexOf(marker);
  if (idx >= 0) {
    const after = p.substring(idx + marker.length);
    if (after.startsWith(`${MENU_IMAGES_BUCKET}/`)) {
      p = after.substring(`${MENU_IMAGES_BUCKET}/`.length);
    }
  }

  // Trim an accidental bucket prefix.
  if (p.startsWith(`${MENU_IMAGES_BUCKET}/`)) {
    p = p.substring(`${MENU_IMAGES_BUCKET}/`.length);
  }

  return { kind: "path", value: p };
}

export function menuImageUrl(pathOrUrl) {
  const normalized = normalizePath(pathOrUrl);
  if (!normalized) return "";
  if (normalized.kind === "url") return normalized.value;
  return supabase.storage.from(MENU_IMAGES_BUCKET).getPublicUrl(normalized.value).data.publicUrl;
}

function sanitizeFilename(name) {
  const base = String(name || "image")
    .trim()
    .toLowerCase()
    .replaceAll(/[^a-z0-9._-]+/g, "-")
    .replaceAll(/-+/g, "-")
    .replaceAll(/^-|-$/g, "");
  return base || "image";
}

export async function uploadMenuImageFile({ file, branchId, itemId }) {
  if (!file) throw new Error("No file selected");
  if (!branchId) throw new Error("Missing branch id");
  if (!itemId) throw new Error("Missing item id");

  const ext = String(file.name || "").split(".").pop();
  const safeExt = ext && ext.length <= 8 ? `.${sanitizeFilename(ext)}` : "";
  const safeName = sanitizeFilename(String(file.name || "menu-image"));
  const ts = Date.now();
  const objectPath = `menu/${branchId}/${itemId}/${ts}-${safeName}${safeExt}`;

  const res = await supabase.storage
    .from(MENU_IMAGES_BUCKET)
    .upload(objectPath, file, {
      cacheControl: "3600",
      upsert: true,
      contentType: file.type || "image/jpeg",
    });
  if (res.error) return { data: null, error: res.error };

  return {
    data: {
      path: objectPath,
      publicUrl: supabase.storage.from(MENU_IMAGES_BUCKET).getPublicUrl(objectPath).data.publicUrl,
    },
    error: null,
  };
}

