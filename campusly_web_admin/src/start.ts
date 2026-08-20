import { createStart, createMiddleware } from "@tanstack/react-start";
import { renderErrorPage } from "./lib/error-page";

const errorMiddleware = createMiddleware().server(async ({ next }) => {
  try {
    return await next();
  } catch (error) {
    if (error != null && typeof error === "object" && "statusCode" in error) {
      throw error;
    }
    console.error(error);
    return new Response(renderErrorPage(), {
      status: 500,
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  }
});

// WORKAROUND for "createCsrfMiddleware is not a function" in TanStack edge bundles
const csrfMiddleware = createMiddleware().server(async ({ next, request }) => {
  // Basic CSRF check for mutations
  if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(request.method)) {
    const origin = request.headers.get('origin');
    const host = request.headers.get('host');
    
    // In edge, URL might not have full origin, but we compare what we can
    if (origin && host && !origin.includes(host)) {
      return new Response("Forbidden: CSRF check failed", { status: 403 });
    }
  }
  return next();
});

export const startInstance = createStart(() => ({
  requestMiddleware: [errorMiddleware, csrfMiddleware],
}));
