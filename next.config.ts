import type { NextConfig } from "next";

const nextConfig: NextConfig = {
    serverExternalPackages: ["puppeteer-core", "@sparticuz/chromium"],
    outputFileTracingIncludes: {
          "/api/product-sheets": ["node_modules/@sparticuz/chromium/bin/**"],
    },
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
