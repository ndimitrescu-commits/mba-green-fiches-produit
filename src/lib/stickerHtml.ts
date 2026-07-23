import type { ProductSheetData } from "@/lib/types";
import { categoryIconSvg } from "@/lib/productCategories";
import { ean13Svg, formatEan13Digits } from "@/lib/barcode";

function esc(v: string | null | undefined): string {
  return v === undefined || v === null || v === "" ? "—" : v;
}

// Product dimensions on the sticker come from the product's own
// height/width/diameter/length fields (not the box/carton dimensions,
// which are a separate, larger measurement). Every field that's actually
// filled in gets shown — e.g. a square sticker with only height + length
// set should read "40 x 40", not silently drop the length because height
// was already present.
function productDimensionsLabel(d: ProductSheetData): string {
  const parts: string[] = [];
  if (d.diameter) parts.push(`Ø${d.diameter}`);
  if (d.height) parts.push(d.height);
  if (d.width) parts.push(d.width);
  if (d.length) parts.push(d.length);
  return parts.length ? parts.join(" x ") : "—";
}

// The SKU / items-per-pack cells sit side by side in a fixed-width column,
// so a long reference (e.g. "STICK01SKRSTY") can overflow and get clipped.
// Rather than truncate it with an ellipsis (illegible on a physical label),
// shrink the font just enough to keep the full value on one line.
function fitValueFontSize(text: string): number {
  const len = (text || "").length;
  if (len <= 9) return 26;
  if (len <= 12) return 21;
  if (len <= 15) return 17;
  if (len <= 18) return 14;
  return 12;
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
          <div class="sticker-cell"><div class="k">SKU:</div><div class="v" style="font-size:${fitValueFontSize(d.ref)}px">${esc(d.ref)}</div></div>
          <div class="sticker-cell"><div class="k">Items per pack:</div><div class="v" style="font-size:${fitValueFontSize(d.unitsPerBox)}px">${esc(d.unitsPerBox)}</div></div>
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
