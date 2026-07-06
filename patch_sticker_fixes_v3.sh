#!/bin/bash
set -e
echo "Applying: fix logo shape/orientation, enlarge barcode + category icon..."

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
  padding:20px; background:#fff; font-family:'Inter',sans-serif; color:#111;
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

cat > src/lib/stickerHtml.ts <<'FILEEOF'
import type { ProductSheetData } from "@/lib/types";
import { categoryIconSvg } from "@/lib/productCategories";
import { ean13Svg, formatEan13Digits } from "@/lib/barcode";

function esc(v: string | null | undefined): string {
  return v === undefined || v === null || v === "" ? "—" : v;
}

// Product dimensions on the sticker come from the product's own
// height/width/diameter/length fields (not the box/carton dimensions,
// which are a separate, larger measurement) — best-effort composition
// since not every SKU has every one of these filled in.
function productDimensionsLabel(d: ProductSheetData): string {
  const parts: string[] = [];
  if (d.diameter) parts.push(`Ø${d.diameter}`);
  if (d.height) parts.push(d.height);
  if (!d.diameter && d.width) parts.push(d.width);
  if (!d.height && !d.width && d.length) parts.push(d.length);
  return parts.length ? parts.join(" x ") : "—";
}

// MBA Green mark for the sticker footer — built as plain SVG (shape + <text>)
// rather than an HTML div with a CSS clip-path: clip-path + text can render
// unreliably inside Chromium's print-to-PDF path (text silently disappearing
// behind the clip), whereas a plain SVG group always prints correctly.
// Shape matches the real logo: wide flat top, narrower flat bottom (like a
// bucket/planter viewed from the front), black-and-white for print.
function mbaGreenLogoSvg(): string {
  return `<svg width="96" height="98" viewBox="0 0 120 122" xmlns="http://www.w3.org/2000/svg">
    <path d="M10 14H110L94 116H26L10 14Z" fill="#111"/>
    <text x="56" y="62" text-anchor="middle" font-family="Inter, sans-serif" font-weight="700" font-size="30" fill="#fff">MBA</text>
    <text x="97" y="38" text-anchor="middle" font-family="Inter, sans-serif" font-weight="600" font-size="12" fill="#fff">TM</text>
    <text x="56" y="94" text-anchor="middle" font-family="Inter, sans-serif" font-weight="600" font-size="22" fill="#fff">Green</text>
  </svg>`;
}

/**
 * Plain-string HTML for the printable carton sticker, rendered server-side
 * to PDF (see stickerPdf.ts) — mirrors the client's existing Illustrator
 * label format (SKU + items per pack, EAN13, product dimensions, category
 * icon, MBA Green mark, barcode) but generated straight from the sheet's
 * own structured fields instead of being made by hand.
 */
export function buildStickerHtml(d: ProductSheetData): string {
  const dims = productDimensionsLabel(d);
  const hasEan = !!d.eanBox;

  return `
  <div class="sticker">
    <div class="sticker-main">
      <div class="sticker-icon">${categoryIconSvg(d.category, 92)}</div>
      <div class="sticker-info">
        <div class="sticker-row sticker-row-split">
          <div class="sticker-cell"><div class="k">SKU:</div><div class="v">${esc(d.ref)}</div></div>
          <div class="sticker-cell"><div class="k">Items per pack:</div><div class="v">${esc(d.unitsPerBox)}</div></div>
        </div>
        <div class="sticker-row">
          <div class="k">EAN 13:</div><div class="v">${esc(d.eanBox)}</div>
        </div>
        <div class="sticker-row">
          <div class="k">Product dimensions:</div><div class="v">${dims}</div>
        </div>
      </div>
    </div>
    <div class="sticker-footer">
      <div class="sticker-logo">${mbaGreenLogoSvg()}</div>
      <div class="sticker-spacer"></div>
      <div class="sticker-barcode">
        ${hasEan ? ean13Svg(d.eanBox, { moduleWidth: 2.6, height: 72 }) : `<div style="font-size:12px;color:#999;">EAN indisponible</div>`}
        <div class="sticker-barcode-digits">${formatEan13Digits(d.eanBox)}</div>
      </div>
    </div>
  </div>`;
}
FILEEOF

git add -A
git status
echo "Done. Review the diff, then: git commit -m \"Fix logo shape, enlarge barcode and category icon\" && git push"
