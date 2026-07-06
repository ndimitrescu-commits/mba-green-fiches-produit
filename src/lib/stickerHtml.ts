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
      <div class="sticker-icon">${categoryIconSvg(d.category)}</div>
      <div class="sticker-info">
        <div class="sticker-row sticker-row-split">
          <div class="sticker-cell"><span class="k">SKU:</span><span class="v">${esc(d.ref)}</span></div>
          <div class="sticker-cell"><span class="k">Items per pack:</span><span class="v">${esc(d.unitsPerBox)}</span></div>
        </div>
        <div class="sticker-row">
          <span class="k">EAN 13:</span><span class="v">${esc(d.eanBox)}</span>
        </div>
        <div class="sticker-row">
          <span class="k">Product dimensions:</span><span class="v">${dims}</span>
        </div>
      </div>
    </div>
    <div class="sticker-footer">
      <div class="sticker-logo">
        <div class="sticker-logo-mark">MBA<span>Green</span></div>
      </div>
      <div class="sticker-spacer"></div>
      <div class="sticker-barcode">
        ${hasEan ? ean13Svg(d.eanBox, { moduleWidth: 2, height: 56 }) : `<div style="font-size:12px;color:#999;">EAN indisponible</div>`}
        <div class="sticker-barcode-digits">${formatEan13Digits(d.eanBox)}</div>
      </div>
    </div>
  </div>`;
}
