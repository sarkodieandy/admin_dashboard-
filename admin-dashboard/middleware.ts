import { NextResponse, type NextRequest } from "next/server";

import { updateSession } from "@/lib/supabase/middleware";

export function middleware(request: NextRequest) {
  const response = updateSession(request);

  const pathname = request.nextUrl.pathname;

  // Back-compat: older links used `/app/*` (route groups don't appear in URLs).
  // Redirect them to the correct top-level routes.
  if (pathname === "/app" || pathname.startsWith("/app/")) {
    const url = request.nextUrl.clone();
    url.pathname = pathname === "/app" ? "/dashboard" : pathname.replace(/^\/app/, "");
    return NextResponse.redirect(url);
  }

  const isAuthRoute = pathname === "/login";
  const isPublicRoute = pathname === "/" || isAuthRoute;

  // Read session cookie presence. The middleware can't reliably call getUser() synchronously,
  // but we can still enforce redirects based on typical cookie names.
  const hasSessionCookie =
    request.cookies.get("sb-access-token") != null ||
    request.cookies.get("sb:token") != null ||
    request.cookies.get("sb-refresh-token") != null ||
    request.cookies.get("sb-refresh-token.0") != null;

  if (!isPublicRoute && !hasSessionCookie) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("redirect", pathname);
    if (process.env.NODE_ENV !== "production") {
      console.debug("[middleware] redirect -> /login", { pathname });
    }
    return NextResponse.redirect(url);
  }

  if (isAuthRoute && hasSessionCookie) {
    const url = request.nextUrl.clone();
    url.pathname = "/dashboard";
    if (process.env.NODE_ENV !== "production") {
      console.debug("[middleware] redirect -> /dashboard (already authed)");
    }
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
