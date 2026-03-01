import { getClient } from "./auth.js";

const supabase = getClient();

export const MENU_IMAGES_BUCKET = "menu-images";
export const RESTAURANT_LOGOS_BUCKET = "restaurant-logos";

function normalizeRemoteUrl(value) {
  let p = String(value || "").trim();
  if (!p) return null;

  p = p.replace(/^['"]+|['"]+$/g, "");
  if (!p) return null;

  if (p.startsWith("//")) {
    p = `https:${p}`;
  } else if (/^www\./i.test(p)) {
    p = `https://${p}`;
  }

  try {
    const url = new URL(p);
    if (
      url.protocol === "http:" &&
      !["localhost", "127.0.0.1"].includes(url.hostname)
    ) {
      url.protocol = "https:";
    }
    return encodeURI(url.toString());
  } catch (_) {
    return null;
  }
}

function normalizePath(path) {
  if (!path) return null;
  let p = String(path).trim();
  if (!p) return null;

  // Already a full URL.
  const remoteUrl = normalizeRemoteUrl(p);
  if (remoteUrl) return { kind: "url", value: remoteUrl };

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

export function normalizeMenuImageValue(pathOrUrl) {
  const normalized = normalizePath(pathOrUrl);
  return normalized?.value || "";
}

export function menuImageUrl(pathOrUrl) {
  const normalized = normalizePath(pathOrUrl);
  if (!normalized) return "";
  if (normalized.kind === "url") return normalized.value;
  return supabase.storage.from(MENU_IMAGES_BUCKET).getPublicUrl(normalized.value).data.publicUrl;
}

export function restaurantLogoUrl(pathOrUrl) {
  const remoteUrl = normalizeRemoteUrl(pathOrUrl);
  return remoteUrl || "";
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

function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(reader.error || new Error("Failed to read image file"));
    reader.onload = () => {
      const result = String(reader.result || "");
      const base64 = result.includes(",") ? result.split(",").pop() : result;
      if (!base64) {
        reject(new Error("Failed to read image data"));
        return;
      }
      resolve(base64);
    };
    reader.readAsDataURL(file);
  });
}

function changeFileExtension(name, ext) {
  const safeExt = String(ext || "").replace(/^\./, "").trim().toLowerCase();
  const base = sanitizeFilename(String(name || "image"));
  const dot = base.lastIndexOf(".");
  const stem = dot > 0 ? base.slice(0, dot) : base;
  return safeExt ? `${stem}.${safeExt}` : stem;
}

function blobToBase64(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(reader.error || new Error("Failed to encode image"));
    reader.onload = () => {
      const result = String(reader.result || "");
      const base64 = result.includes(",") ? result.split(",").pop() : result;
      if (!base64) {
        reject(new Error("Failed to encode image data"));
        return;
      }
      resolve(base64);
    };
    reader.readAsDataURL(blob);
  });
}

function canvasToBlob(canvas, type, quality) {
  return new Promise((resolve) => {
    canvas.toBlob((blob) => resolve(blob), type, quality);
  });
}

function loadImageFromFile(file) {
  return new Promise((resolve, reject) => {
    const objectUrl = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(objectUrl);
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      reject(new Error("Failed to load image"));
    };
    img.src = objectUrl;
  });
}

async function optimizeImageForUpload(file) {
  const isImage = String(file?.type || "").startsWith("image/");
  if (!file || !isImage) {
    throw new Error("Select a valid image file");
  }

  const safeName = sanitizeFilename(String(file.name || "menu-image"));
  const originalBase64 = await fileToBase64(file);

  // Keep animated GIFs and SVGs as-is.
  if (["image/gif", "image/svg+xml"].includes(file.type)) {
    return {
      filename: safeName,
      contentType: file.type || "application/octet-stream",
      fileBase64: originalBase64,
      optimized: false,
    };
  }

  const originalBytes = file.size || Math.ceil((originalBase64.length * 3) / 4);
  const shouldOptimize = originalBytes > 1.5 * 1024 * 1024;
  if (!shouldOptimize) {
    return {
      filename: safeName,
      contentType: file.type || "image/jpeg",
      fileBase64: originalBase64,
      optimized: false,
    };
  }

  const image = await loadImageFromFile(file);
  const maxDimension = 1600;
  const width = image.naturalWidth || image.width || 0;
  const height = image.naturalHeight || image.height || 0;
  if (!width || !height) {
    return {
      filename: safeName,
      contentType: file.type || "image/jpeg",
      fileBase64: originalBase64,
      optimized: false,
    };
  }

  const scale = Math.min(1, maxDimension / Math.max(width, height));
  const targetWidth = Math.max(1, Math.round(width * scale));
  const targetHeight = Math.max(1, Math.round(height * scale));
  const canvas = document.createElement("canvas");
  canvas.width = targetWidth;
  canvas.height = targetHeight;
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    return {
      filename: safeName,
      contentType: file.type || "image/jpeg",
      fileBase64: originalBase64,
      optimized: false,
    };
  }

  ctx.drawImage(image, 0, 0, targetWidth, targetHeight);

  let outputType = file.type === "image/png" && originalBytes <= 2.5 * 1024 * 1024
    ? "image/png"
    : "image/jpeg";
  let blob = await canvasToBlob(canvas, outputType, 0.84);

  if (!blob && outputType !== "image/jpeg") {
    outputType = "image/jpeg";
    blob = await canvasToBlob(canvas, outputType, 0.84);
  }
  if (!blob) {
    return {
      filename: safeName,
      contentType: file.type || "image/jpeg",
      fileBase64: originalBase64,
      optimized: false,
    };
  }

  if (blob.size >= originalBytes * 0.97) {
    return {
      filename: safeName,
      contentType: file.type || "image/jpeg",
      fileBase64: originalBase64,
      optimized: false,
    };
  }

  return {
    filename: changeFileExtension(safeName, outputType === "image/png" ? "png" : "jpg"),
    contentType: outputType,
    fileBase64: await blobToBase64(blob),
    optimized: true,
  };
}

export async function uploadMenuImageFile({ file, branchId, itemId }) {
  if (!file) throw new Error("No file selected");
  if (!branchId) throw new Error("Missing branch id");
  if (!itemId) throw new Error("Missing item id");
  if (file.size > 20 * 1024 * 1024) {
    return {
      data: null,
      error: { message: "Image is too large. Use an image under 20MB." },
    };
  }

  const prepared = await optimizeImageForUpload(file);
  const estimatedPayloadBytes = Math.ceil((prepared.fileBase64.length * 3) / 4);
  if (estimatedPayloadBytes > 3.5 * 1024 * 1024) {
    return {
      data: null,
      error: {
        message:
          "Image is still too large after optimization. Use a smaller photo or crop it first.",
      },
    };
  }

  const fnRes = await supabase.functions.invoke("admin-upload-menu-image", {
    body: {
      branch_id: branchId,
      item_id: itemId,
      filename: prepared.filename,
      content_type: prepared.contentType,
      file_base64: prepared.fileBase64,
    },
  });
  if (!fnRes.error) {
    return {
      data: {
        path: fnRes.data?.path || null,
        publicUrl: fnRes.data?.publicUrl || "",
      },
      error: null,
    };
  }

  let message = fnRes.error.message || "Failed to upload menu image";
  try {
    const fnError = await fnRes.error.context?.json?.();
    if (fnError?.error) {
      message = fnError.error;
    }
  } catch (_) {
    // Keep top-level function message.
  }

  const lower = String(message || "").toLowerCase();
  if (
    lower.includes("failed to send a request to the edge function") ||
    lower.includes("functionsfetcherror") ||
    lower.includes("failed to fetch")
  ) {
    message =
      "Image upload request failed before reaching Supabase. Redeploy `admin-upload-menu-image`, then retry with a smaller image.";
  }

  console.error("[E][menu] upload_menu_image_failed", {
    branchId,
    itemId,
    filename: file.name || "",
    optimized: prepared.optimized,
    error: fnRes.error,
    message,
  });

  return {
    data: null,
    error: {
      ...fnRes.error,
      message,
    },
  };
}

export async function uploadRestaurantLogoFile({ file, restaurantName, slugHint }) {
  if (!file) throw new Error("No file selected");
  if (file.size > 20 * 1024 * 1024) {
    return {
      data: null,
      error: { message: "Image is too large. Use an image under 20MB." },
    };
  }

  const prepared = await optimizeImageForUpload(file);
  const estimatedPayloadBytes = Math.ceil((prepared.fileBase64.length * 3) / 4);
  if (estimatedPayloadBytes > 3.5 * 1024 * 1024) {
    return {
      data: null,
      error: {
        message:
          "Image is still too large after optimization. Use a smaller photo or crop it first.",
      },
    };
  }

  const fnRes = await supabase.functions.invoke("admin-upload-restaurant-logo", {
    body: {
      filename: prepared.filename,
      content_type: prepared.contentType,
      file_base64: prepared.fileBase64,
      restaurant_name: String(restaurantName || "").trim() || null,
      slug_hint: String(slugHint || "").trim() || null,
    },
  });
  if (!fnRes.error) {
    return {
      data: {
        path: fnRes.data?.path || null,
        publicUrl: fnRes.data?.publicUrl || "",
      },
      error: null,
    };
  }

  let message = fnRes.error.message || "Failed to upload restaurant logo";
  try {
    const fnError = await fnRes.error.context?.json?.();
    if (fnError?.error) {
      message = fnError.error;
    }
  } catch (_) {
    // Keep top-level function message.
  }

  const lower = String(message || "").toLowerCase();
  if (
    lower.includes("failed to send a request to the edge function") ||
    lower.includes("functionsfetcherror") ||
    lower.includes("failed to fetch")
  ) {
    message =
      "Restaurant logo upload request failed before reaching Supabase. Deploy `admin-upload-restaurant-logo` and retry.";
  }

  console.error("[E][restaurant] upload_restaurant_logo_failed", {
    restaurantName,
    slugHint,
    filename: file.name || "",
    optimized: prepared.optimized,
    error: fnRes.error,
    message,
  });

  return {
    data: null,
    error: {
      ...fnRes.error,
      message,
    },
  };
}
