"use client";

import { useEffect, useRef } from "react";

interface Star {
  x: number;
  y: number;
  z: number;
  pz: number;
  speed: number;
  color: string;
}

export function WarpStarField() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrameId: number;
    let width = window.innerWidth;
    let height = window.innerHeight;
    canvas.width = width;
    canvas.height = height;

    // Respect prefers-reduced-motion
    const prefersReducedMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;

    const STARS_COUNT = 400; // Controlled density for readability
    const Z_MAX = 2000;
    const FOV = 800; // Field of view multiplier
    const BASE_SPEED = prefersReducedMotion ? 0 : 2.5;

    const stars: Star[] = [];

    // Colors: mostly white/gray, 10% Campusly Blue (#76cefa or #3b82f6)
    const getStarColor = () => {
      return Math.random() > 0.9 ? "59, 130, 246" : "0, 0, 0"; // Campusly Blue or Black
    };

    for (let i = 0; i < STARS_COUNT; i++) {
      stars.push({
        x: (Math.random() - 0.5) * 2000,
        y: (Math.random() - 0.5) * 2000,
        z: Math.random() * Z_MAX,
        pz: 0,
        speed: BASE_SPEED + Math.random() * 2,
        color: getStarColor(),
      });
    }

    // Ensure pz is initialized correctly
    stars.forEach((s) => {
      s.pz = s.z;
    });

    const render = () => {
      ctx.fillStyle = "#ffffff";
      ctx.fillRect(0, 0, width, height);

      const cx = width / 2;
      const cy = height / 2;

      stars.forEach((star) => {
        if (!prefersReducedMotion) {
          star.pz = star.z;
          star.z -= star.speed;

          if (star.z <= 0) {
            star.z = Z_MAX;
            star.pz = Z_MAX;
            star.x = (Math.random() - 0.5) * 2000;
            star.y = (Math.random() - 0.5) * 2000;
          }
        }

        // Projection
        const sx = (star.x / star.z) * FOV + cx;
        const sy = (star.y / star.z) * FOV + cy;
        const px = (star.x / star.pz) * FOV + cx;
        const py = (star.y / star.pz) * FOV + cy;

        // Depth-based attributes
        // Far away (Z_MAX) -> opacity 0. Close (0) -> opacity 1
        const depthRatio = 1 - star.z / Z_MAX;
        const opacity = Math.min(1, Math.max(0.1, depthRatio * 1.2));
        const lineWidth = Math.max(0.5, depthRatio * 3);

        ctx.beginPath();
        ctx.strokeStyle = `rgba(${star.color}, ${opacity})`;
        ctx.lineWidth = lineWidth;
        
        if (prefersReducedMotion) {
          // Draw just a dot if no motion
          ctx.arc(sx, sy, lineWidth, 0, Math.PI * 2);
          ctx.fillStyle = `rgba(${star.color}, ${opacity})`;
          ctx.fill();
        } else {
          // Draw a streak
          ctx.moveTo(px, py);
          ctx.lineTo(sx, sy);
          ctx.stroke();
        }
      });

      if (!prefersReducedMotion) {
        animationFrameId = requestAnimationFrame(render);
      }
    };

    if (prefersReducedMotion) {
      render(); // Render once
    } else {
      animationFrameId = requestAnimationFrame(render);
    }

    const handleResize = () => {
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = width;
      canvas.height = height;
      if (prefersReducedMotion) {
        render(); // Re-render on resize if static
      }
    };

    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      if (animationFrameId) {
        cancelAnimationFrame(animationFrameId);
      }
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 z-0 h-full w-full pointer-events-none"
      aria-hidden="true"
    />
  );
}
