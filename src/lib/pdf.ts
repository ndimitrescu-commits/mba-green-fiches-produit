import "server-only";
import type { ProductSheetData } from "@/lib/types";
import { SHEET_CSS } from "@/lib/sheetCss";
import { buildSheetHtml } from "@/lib/sheetHtml";

function buildHtmlDocument(data: ProductSheetData): string {
  const markup = `<div class="sheet">${buildSheetHtml(data)}</div>`;
  return `<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>${data.ref || "Fiche produit"} — MBA Green</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
  html,body{margin:0;padding:0;}
  ${SHEET_CSS}
</style>
</head>
<body>
${markup}
</body>
</html>`;
}

/**
 * Renders a product sheet to a PDF buffer, server-side, using the exact same
 * React component (ProductSheetView) that powers the on-screen live preview
 * and the directory modal. This is what guarantees "what you see is what
 * gets generated" as required by the brief.
 *
 * Uses puppeteer-core + @sparticuz/chromium so it runs both locally (Linux)
 * and inside Vercel's serverless functions without bundling a full Chromium
 * download.
 */
export async function generateSheetPdf(data: ProductSheetData): Promise<Buffer> {
  const puppeteer = await import("puppeteer-core");
  const chromium = (await import("@sparticuz/chromium")).default;

  const executablePath = await chromium.executablePath();

  const browser = await puppeteer.launch({
    args: chromium.args,
    executablePath,
    headless: true,
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 794, height: 1123 });
    await page.setContent(buildHtmlDocument(data), { waitUntil: "load" });
    const pdf = await page.pdf({
      width: "794px",
      height: "1123px",
      printBackground: true,
      margin: { top: 0, bottom: 0, left: 0, right: 0 },
    });
    return Buffer.from(pdf);
  } finally {
    await browser.close();
  }
}
