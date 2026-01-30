"use client";

import * as React from "react";

import { cn } from "@/lib/utils";

type EmojiIconProps = {
  /** Twemoji codepoint, e.g. "1f35b" (fried rice). */
  code: string;
  alt: string;
  className?: string;
};

const twemojiBase = "https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72";

export function EmojiIcon({ code, alt, className }: EmojiIconProps) {
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={`${twemojiBase}/${code}.png`}
      alt={alt}
      className={cn("h-4 w-4", className)}
      loading="lazy"
      decoding="async"
    />
  );
}

