"use client";

import * as React from "react";
import { usePathname } from "next/navigation";

export function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  return (
    <div key={pathname} className="motion-safe:animate-[fadeUp_.26s_ease-out]">
      {children}
    </div>
  );
}

