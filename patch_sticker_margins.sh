#!/bin/bash
set -e
echo "Applying: fix uneven sticker margins (PDF page size mismatch)..."

cat > src/lib/stickerCss.ts <<'FILEEOF'
// Inline CSS for the printable carton sticker (see stickerHtml.ts / stickerPdf.ts).
// Kept as a standalone string so the PDF route can embed it in a plain HTML
// document — same pattern as sheetCss.ts for the main datasheet. Layout
// mirrors the client's own Illustrator-made sticker as closely as possible:
// thin card border, stacked label-then-bold-value cells, icon + logo on the
// left, EAN13 barcode bottom-right.
export const STICKER_CSS = `
*{box-sizing:border-box;}
html,body{margin:0;padding:0;}
body{
  padding:14px; background:#fff; font-family:'Inter',sans-serif; color:#111;
}
.sticker{
  width:660px; height:360px;
  border:3px solid #111; border-radius:34px; overflow:hidden;
  display:flex; flex-direction:column; background:#fff;
}
.sticker-main{ display:flex; flex:1; }
.sticker-icon{
  width:160px; flex-shrink:0;
  border-right:1.5px solid #111; border-bottom:1.5px solid #111;
  display:flex; align-items:center; justify-content:center;
}
.sticker-info{ flex:1; display:flex; flex-direction:column; min-width:0; }
.sticker-row{
  flex:1; border-bottom:1.5px solid #111; display:flex; align-items:stretch; min-width:0;
}
.sticker-row:not(.sticker-row-split){ flex-direction:column; justify-content:center; padding:0 26px; }
.sticker-cell{ flex:1; padding:0 26px; display:flex; flex-direction:column; justify-content:center; min-width:0; }
.sticker-cell:first-child{ border-right:1.5px solid #111; }
.k{ font-size:15px; font-weight:500; color:#111; white-space:nowrap; line-height:1; }
.v{ font-size:26px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; line-height:1.2; margin-top:3px; }
.sticker-footer{ height:132px; display:flex; align-items:stretch; }
.sticker-logo{
  width:160px; flex-shrink:0; border-right:1.5px solid #111;
  display:flex; align-items:center; justify-content:center;
}
.sticker-spacer{ flex:1; }
.sticker-barcode{ display:flex; flex-direction:column; align-items:center; justify-content:center; padding-right:28px; }
.sticker-barcode-digits{ font-size:17px; letter-spacing:2px; margin-top:4px; }
`;
FILEEOF

cat > src/lib/stickerPdf.ts <<'FILEEOF'
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
    // Page size must exactly match the .sticker card (660x360, see
    // stickerCss.ts) plus its surrounding body padding on every side — any
    // mismatch here leaves an uneven margin (previously: 0px on the right,
    // 40px on the bottom, instead of a uniform frame all around).
    await page.setViewport({ width: 688, height: 388 });
    await page.setContent(buildHtmlDocument(data), { waitUntil: "load" });
    const pdf = await page.pdf({
      width: "688px",
      height: "388px",
      printBackground: true,
      margin: { top: 0, bottom: 0, left: 0, right: 0 },
    });
    return Buffer.from(pdf);
  } finally {
    await browser.close();
  }
}
FILEEOF

git add -A
git status
echo "Done. Review the diff, then: git commit -m \"Fix uneven sticker margins\" && git push"
