import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // puppeteer-core / @sparticuz/chromium ship native binaries and must not
  // be bundled by webpack — keep them as real Node dependencies at runtime,
  // both locally and in the Vercel serverless function.
  serverExternalPackages: ["puppeteer-core", "@sparticuz/chromium"],
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "**.supabase.co",
      },
    ],
  },
};

export default nextConfig;
