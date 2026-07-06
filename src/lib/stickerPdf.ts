import "server-only";
import type { ProductSheetData } from "@/lib/types";
import { STICKER_CSS } from "@/lib/stickerCss";
import { buildStickerHtml } from "@/lib/stickerHtml";

function buildHtmlDocument(data: ProductSheetData): string {
  const markup = buildStickerHtml(data);
  return `<!DOCTYPE html>
  <html lang="fr">
  <head>
  <meta charset="UTF-8">
  <title>Sticker ${data.ref || ""} MBA Green</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
  html,body{margin:0;padding:0;}
  ${STICKER_CSS}
  </style>
  </head>
  <body>
  ${markup}
  </body>
  </html>`;
}

/**
 * Renders the carton sticker (see stickerHtml.ts) to a PDF buffer,
 * server-side — generated on demand, nothing is stored. Same
 * puppeteer-core + @sparticuz/chromium approach as generateSheetPdf
 * (src/lib/pdf.ts) so it works both locally and on Vercel.
 */
export async function generateStickerPdf(data: ProductSheetData): Promise<Buffer> {
  const puppeteer = await import("puppeteer-core");
  const chromium = (await import("@sparticuz/chromium")).default;
  const path = await import("node:path");
  const fs = await import("node:fs");

  const explicitBinPath = path.join(process.cwd(), "node_modules/@sparticuz/chromium/bin");
  const executablePath = await chromium.executablePath(
    fs.existsSync(explicitBinPath) ? explicitBinPath : undefined
  );

  const browser = await puppeteer.launch({
    args: chromium.args,
    executablePath,
    headless: true,
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 680, height: 420 });
    await page.setContent(buildHtmlDocument(data), { waitUntil: "load" });
    const pdf = await page.pdf({
      width: "680px",
      height: "420px",
      printBackground: true,
      margin: { top: 0, bottom: 0, left: 0, right: 0 },
    });
    return Buffer.from(pdf);
  } finally {
    await browser.close();
  }
}
