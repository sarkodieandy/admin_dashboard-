"use client";

export function errorMessage(err: unknown) {
  if (!err) return "Unknown error";
  if (typeof err === "string") return err;
  if (err instanceof Error) return err.message;

  if (typeof err === "object") {
    const anyErr = err as Record<string, unknown>;
    const message = typeof anyErr.message === "string" ? anyErr.message : null;
    const details = typeof anyErr.details === "string" ? anyErr.details : null;
    const hint = typeof anyErr.hint === "string" ? anyErr.hint : null;
    const code = typeof anyErr.code === "string" ? anyErr.code : null;
    const parts = [message, details, hint].filter(Boolean) as string[];
    const base = parts.length ? parts.join(" — ") : JSON.stringify(err);
    return code ? `${base} (code ${code})` : base;
  }

  return String(err);
}

