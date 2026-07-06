#!/bin/bash
set -e
echo "Applying: carton sticker generation feature..."

mkdir -p src/lib
cat > src/lib/barcode.ts <<'FILEEOF'
import "server-only";

// Minimal, dependency-free EAN-13 barcode encoder. Renders straight to an
// inline SVG string that gets embedded directly in the sticker's
// server-rendered HTML (see stickerHtml.ts) — no browser JS, no external
// library, so it works reliably inside the same headless-Chromium PDF
// pipeline used for the main datasheet (see pdf.ts).

const L_CODES: Record<string, string> = {
  "0": "0001101", "1": "0011001", "2": "0010011", "3": "0111101", "4": "0100011",
  "5": "0110001", "6": "0101111", "7": "0111011", "8": "0110111", "9": "0001011",
};
const G_CODES: Record<string, string> = {
  "0": "0100111", "1": "0110011", "2": "0011011", "3": "0100001", "4": "0011101",
  "5": "0111001", "6": "0000101", "7": "0010001", "8": "0001001", "9": "0010111",
};
const R_CODES: Record<string, string> = {
  "0": "1110010", "1": "1100110", "2": "1101100", "3": "1000010", "4": "1011100",
  "5": "1001110", "6": "1010000", "7": "1000100", "8": "1001000", "9": "1110100",
};
const FIRST_DIGIT_PARITY: Record<string, string> = {
  "0": "LLLLLL", "1": "LLGLGG", "2": "LLGGLG", "3": "LLGGGL", "4": "LGLLGG",
  "5": "LGGLLG", "6": "LGGGLL", "7": "LGLGLG", "8": "LGLGGL", "9": "LGGLGL",
};

interface Ean13Encoded {
  bars: string; // 95-char string of '0'/'1', one char per module
}

// Returns null if the input isn't a plausible 13-digit EAN code — callers
// should fall back to showing the raw digits without a barcode graphic.
function encodeEan13(code: string): Ean13Encoded | null {
  const digits = (code || "").replace(/\s+/g, "");
  if (!/^\d{13}$/.test(digits)) return null;

  const parity = FIRST_DIGIT_PARITY[digits[0]];
  let bars = "101"; // start guard
  for (let i = 0; i < 6; i++) {
    const d = digits[1 + i];
    bars += parity[i] === "L" ? L_CODES[d] : G_CODES[d];
  }
  bars += "01010"; // middle guard
  for (let i = 0; i < 6; i++) {
    bars += R_CODES[digits[7 + i]];
  }
  bars += "101"; // end guard
  return { bars };
}

export function ean13Svg(code: string, opts?: { moduleWidth?: number; height?: number }): string {
  const encoded = encodeEan13(code);
  const moduleWidth = opts?.moduleWidth ?? 2.2;
  const barHeight = opts?.height ?? 60;
  if (!encoded) {
    return `<div style="font-size:11px;color:#999;">Code-barres indisponible</div>`;
  }
  const width = encoded.bars.length * moduleWidth;
  let rects = "";
  let x = 0;
  for (const bit of encoded.bars) {
    if (bit === "1") {
      rects += `<rect x="${x.toFixed(2)}" y="0" width="${moduleWidth.toFixed(2)}" height="${barHeight}" fill="#000"/>`;
    }
    x += moduleWidth;
  }
  return `<svg width="${width.toFixed(2)}" height="${barHeight}" viewBox="0 0 ${width.toFixed(2)} ${barHeight}" xmlns="http://www.w3.org/2000/svg">${rects}</svg>`;
}

// Groups digits the way GS1 labels print them under the bars, e.g.
// "3 760355 531662" — first digit, then two groups of six.
export function formatEan13Digits(code: string | null | undefined): string {
  const digits = (code || "").replace(/\s+/g, "");
  if (!/^\d{13}$/.test(digits)) return code || "—";
  return `${digits[0]} ${digits.slice(1, 7)} ${digits.slice(7, 13)}`;
}
FILEEOF

mkdir -p src/lib
cat > src/lib/productCategories.ts <<'FILEEOF'
// Fixed list of product categories used to (a) let each SKU be tagged with
// a product type in the "Nouvelle fiche" form, and (b) pick the matching
// pictogram shown on the generated carton sticker (see stickerHtml.ts).

export type ProductCategory =
  | "bag"
  | "bottle"
  | "bowl"
  | "box"
  | "cup"
  | "cutlery"
  | "lid"
  | "napkin"
  | "paper"
  | "pot"
  | "straw"
  | "tray"
  | "other";

export const PRODUCT_CATEGORIES: { value: ProductCategory; label: string }[] = [
  { value: "bag", label: "Sac / pochette" },
  { value: "bottle", label: "Bouteille" },
  { value: "bowl", label: "Bol / bowl" },
  { value: "box", label: "Boîte / carton" },
  { value: "cup", label: "Gobelet" },
  { value: "cutlery", label: "Couverts" },
  { value: "lid", label: "Couvercle" },
  { value: "napkin", label: "Serviette" },
  { value: "paper", label: "Papier / sachet / film" },
  { value: "pot", label: "Pot / ramequin" },
  { value: "straw", label: "Paille / pique / touillette" },
  { value: "tray", label: "Plateau" },
  { value: "other", label: "Autre" },
];

// Simple flat-black pictograms, one per category, 64x64 viewBox. Kept as
// raw path/shape markup (no <svg> wrapper) so the same strings can be
// embedded both in server-rendered PDF HTML (stickerHtml.ts) and, if ever
// needed, in a React component.
const ICON_SHAPES: Record<ProductCategory, string> = {
  bag: `<rect x="16" y="12" width="32" height="10"/><polygon points="14,24 50,24 45,56 19,56"/>`,
  bottle: `<rect x="27" y="6" width="10" height="12" rx="2"/><rect x="20" y="18" width="24" height="38" rx="6"/>`,
  bowl: `<ellipse cx="32" cy="20" rx="22" ry="6"/><path d="M10 22 Q10 48 32 48 Q54 48 54 22 Z"/>`,
  box: `<polygon points="12,20 32,8 52,20"/><rect x="12" y="20" width="40" height="32"/><rect x="30" y="20" width="4" height="32" fill="#fff"/>`,
  cup: `<ellipse cx="32" cy="12" rx="14" ry="3"/><path d="M18 12h28l-5 42H23z"/>`,
  cutlery: `<rect x="22" y="6" width="4" height="26"/><rect x="30" y="6" width="4" height="26"/><rect x="38" y="6" width="4" height="26"/><rect x="20" y="28" width="24" height="6"/><rect x="29" y="30" width="6" height="28"/>`,
  lid: `<path d="M10 42 Q10 16 32 16 Q54 16 54 42 Z"/><rect x="28" y="10" width="8" height="8" rx="2"/>`,
  napkin: `<polygon points="14,16 40,14 42,20 38,30 42,42 36,50 40,58 16,56 18,44 14,36 18,26"/>`,
  paper: `<path d="M14 8h26l10 10v38H14z"/><path d="M40 8v10h10z" fill="#fff"/>`,
  pot: `<rect x="14" y="20" width="36" height="6" rx="2"/><path d="M16 26h32l-3 24a5 5 0 0 1-5 5H24a5 5 0 0 1-5-5z"/>`,
  straw: `<rect x="29" y="4" width="6" height="54" transform="rotate(18 32 32)"/>`,
  tray: `<path fill-rule="evenodd" d="M6 30a26 10 0 1 0 52 0a26 10 0 1 0 -52 0zM16 30a16 6 0 1 1 32 0a16 6 0 1 1 -32 0z"/>`,
  other: `<rect x="14" y="14" width="36" height="36" rx="8" fill="none" stroke="#111" stroke-width="4"/>`,
};

export function categoryIconSvg(category: string | null | undefined, size = 56): string {
  const key = (PRODUCT_CATEGORIES.some((c) => c.value === category) ? category : "other") as ProductCategory;
  return `<svg viewBox="0 0 64 64" width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg" fill="#111">${ICON_SHAPES[key]}</svg>`;
}

export function categoryLabel(category: string | null | undefined): string {
  return PRODUCT_CATEGORIES.find((c) => c.value === category)?.label ?? "Autre";
}
FILEEOF

mkdir -p src/lib
cat > src/lib/stickerCss.ts <<'FILEEOF'
// Inline CSS for the printable carton sticker (see stickerHtml.ts / stickerPdf.ts).
// Kept as a standalone string so the PDF route can embed it in a plain HTML
// document — same pattern as sheetCss.ts for the main datasheet.
export const STICKER_CSS = `
*{box-sizing:border-box;}
html,body{margin:0;padding:0;}
body{
  padding:20px; background:#fff; font-family:'Inter',sans-serif; color:#111;
}
.sticker{
  width:640px; height:380px;
  border:4px solid #111; border-radius:28px; overflow:hidden;
  display:flex; flex-direction:column; background:#fff;
}
.sticker-main{ display:flex; flex:1; }
.sticker-icon{
  width:150px; flex-shrink:0;
  border-right:2px solid #111; border-bottom:2px solid #111;
  display:flex; align-items:center; justify-content:center;
}
.sticker-info{ flex:1; display:flex; flex-direction:column; min-width:0; }
.sticker-row{
  flex:1; border-bottom:2px solid #111; display:flex; align-items:center; padding:0 22px; gap:8px; min-width:0;
}
.sticker-row-split{ padding:0; }
.sticker-cell{ flex:1; padding:0 22px; display:flex; align-items:center; gap:8px; min-width:0; }
.sticker-cell:first-child{ border-right:2px solid #111; }
.k{ font-size:16px; color:#111; white-space:nowrap; }
.v{ font-size:22px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.sticker-footer{ height:110px; display:flex; align-items:stretch; }
.sticker-logo{
  width:150px; flex-shrink:0; border-right:2px solid #111;
  display:flex; align-items:center; justify-content:center;
}
.sticker-logo-mark{
  background:#111; color:#fff; font-weight:700; font-size:14px; text-align:center; line-height:1.15;
  padding:12px 16px; clip-path: polygon(15% 0, 85% 0, 100% 100%, 0% 100%);
}
.sticker-logo-mark span{ display:block; font-size:14px; }
.sticker-spacer{ flex:1; }
.sticker-barcode{ display:flex; flex-direction:column; align-items:center; justify-content:center; padding-right:26px; }
.sticker-barcode-digits{ font-size:15px; letter-spacing:2px; margin-top:2px; }
`;
FILEEOF

mkdir -p src/lib
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
FILEEOF

mkdir -p src/lib
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
FILEEOF

mkdir -p src/lib
cat > src/lib/types.ts <<'FILEEOF'
// Core data shape for a product sheet (fiche produit).
// Field names are camelCase in the app/UI layer; the Supabase table uses snake_case
// (see supabaseRowToSheet / sheetToSupabaseRow below for the mapping).

export interface ProductSheetData {
  id?: string;
  ref: string;
  nameFr: string;
  nameEn: string;
  eanBox: string;
  eanUvc: string;
  customCode: string;
  category: string;

  material: string;
  capacity: string;
  height: string;
  diameter: string;
  length: string;
  gusset: string;
  width: string;
  netWeight: string;

  unitsPerUvc: string;
  uvcWeight: string;

  unitsPerBox: string;
  boxDim: string;
  boxGross: string;
  boxNet: string;
  boxVolume: string;

  unitsPerPallet: string;
  boxesPerPallet: string;
  layersPerPallet: string;
  boxesPerLayer: string;
  palletHeight: string;
  palletWeight: string;
  palletVolume: string;

  tolerance: string;
  imageUrl?: string | null;
  pdfUrl?: string | null;
  createdAt?: string;
  updatedAt?: string;
}

export const EMPTY_SHEET: ProductSheetData = {
  ref: "",
  nameFr: "",
  nameEn: "",
  eanBox: "",
  eanUvc: "",
  customCode: "",
  category: "",
  material: "",
  capacity: "",
  height: "",
  diameter: "",
  length: "",
  gusset: "",
  width: "",
  netWeight: "",
  unitsPerUvc: "",
  uvcWeight: "",
  unitsPerBox: "",
  boxDim: "",
  boxGross: "",
  boxNet: "",
  boxVolume: "",
  unitsPerPallet: "",
  boxesPerPallet: "",
  layersPerPallet: "",
  boxesPerLayer: "",
  palletHeight: "",
  palletWeight: "",
  palletVolume: "",
  tolerance: "",
  imageUrl: null,
  pdfUrl: null,
};

// Row shape as stored in the Supabase `product_sheets` table (snake_case).
export interface ProductSheetRow {
  id: string;
  ref: string;
  name_fr: string | null;
  name_en: string | null;
  ean_box: string | null;
  ean_uvc: string | null;
  custom_code: string | null;
  category: string | null;
  material: string | null;
  capacity: string | null;
  height: string | null;
  diameter: string | null;
  length: string | null;
  gusset: string | null;
  width: string | null;
  net_weight: string | null;
  units_per_uvc: string | null;
  uvc_weight: string | null;
  units_per_box: string | null;
  box_dim: string | null;
  box_gross: string | null;
  box_net: string | null;
  box_volume: string | null;
  units_per_pallet: string | null;
  boxes_per_pallet: string | null;
  layers_per_pallet: string | null;
  boxes_per_layer: string | null;
  pallet_height: string | null;
  pallet_weight: string | null;
  pallet_volume: string | null;
  tolerance: string | null;
  image_url: string | null;
  pdf_url: string | null;
  created_at: string;
  updated_at: string;
}

export function rowToSheet(row: ProductSheetRow): ProductSheetData {
  return {
    id: row.id,
    ref: row.ref ?? "",
    nameFr: row.name_fr ?? "",
    nameEn: row.name_en ?? "",
    eanBox: row.ean_box ?? "",
    eanUvc: row.ean_uvc ?? "",
    customCode: row.custom_code ?? "",
    category: row.category ?? "",
    material: row.material ?? "",
    capacity: row.capacity ?? "",
    height: row.height ?? "",
    diameter: row.diameter ?? "",
    length: row.length ?? "",
    gusset: row.gusset ?? "",
    width: row.width ?? "",
    netWeight: row.net_weight ?? "",
    unitsPerUvc: row.units_per_uvc ?? "",
    uvcWeight: row.uvc_weight ?? "",
    unitsPerBox: row.units_per_box ?? "",
    boxDim: row.box_dim ?? "",
    boxGross: row.box_gross ?? "",
    boxNet: row.box_net ?? "",
    boxVolume: row.box_volume ?? "",
    unitsPerPallet: row.units_per_pallet ?? "",
    boxesPerPallet: row.boxes_per_pallet ?? "",
    layersPerPallet: row.layers_per_pallet ?? "",
    boxesPerLayer: row.boxes_per_layer ?? "",
    palletHeight: row.pallet_height ?? "",
    palletWeight: row.pallet_weight ?? "",
    palletVolume: row.pallet_volume ?? "",
    tolerance: row.tolerance ?? "",
    imageUrl: row.image_url,
    pdfUrl: row.pdf_url,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function sheetToInsertRow(d: ProductSheetData) {
  return {
    ref: d.ref,
    name_fr: d.nameFr || null,
    name_en: d.nameEn || null,
    ean_box: d.eanBox || null,
    ean_uvc: d.eanUvc || null,
    custom_code: d.customCode || null,
    category: d.category || null,
    material: d.material || null,
    capacity: d.capacity || null,
    height: d.height || null,
    diameter: d.diameter || null,
    length: d.length || null,
    gusset: d.gusset || null,
    width: d.width || null,
    net_weight: d.netWeight || null,
    units_per_uvc: d.unitsPerUvc || null,
    uvc_weight: d.uvcWeight || null,
    units_per_box: d.unitsPerBox || null,
    box_dim: d.boxDim || null,
    box_gross: d.boxGross || null,
    box_net: d.boxNet || null,
    box_volume: d.boxVolume || null,
    units_per_pallet: d.unitsPerPallet || null,
    boxes_per_pallet: d.boxesPerPallet || null,
    layers_per_pallet: d.layersPerPallet || null,
    boxes_per_layer: d.boxesPerLayer || null,
    pallet_height: d.palletHeight || null,
    pallet_weight: d.palletWeight || null,
    pallet_volume: d.palletVolume || null,
    tolerance: d.tolerance || null,
    image_url: d.imageUrl || null,
    pdf_url: d.pdfUrl || null,
  };
}

export function materialFamily(material: string | null | undefined): string {
  const mat = (material || "").toUpperCase();
  if (mat.includes("CORRUGAT")) return "Carton cannelé";
  if (mat.includes("PE") || mat.includes("PLASTIC")) return "Papier + PE";
  if (mat.includes("PAPER") || mat.includes("PAPIER")) return "Papier";
  return "Autre";
}
FILEEOF

mkdir -p src/components
cat > src/components/NouvelleFicheClient.tsx <<'FILEEOF'
"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { EMPTY_SHEET, type ProductSheetData } from "@/lib/types";
import { PRODUCT_CATEGORIES } from "@/lib/productCategories";
import ProductSheetView from "@/components/ProductSheetView";

type Field = keyof ProductSheetData;

function Text({
  label,
  field,
  placeholder,
  value,
  onChange,
}: {
  label: string;
  field: Field;
  placeholder?: string;
  value: string;
  onChange: (field: Field, value: string) => void;
}) {
  return (
    <div>
      <label>{label}</label>
      <input
        type="text"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(field, e.target.value)}
      />
    </div>
  );
}

function Select({
  label,
  field,
  options,
  value,
  onChange,
}: {
  label: string;
  field: Field;
  options: { value: string; label: string }[];
  value: string;
  onChange: (field: Field, value: string) => void;
}) {
  return (
    <div>
      <label>{label}</label>
      <select value={value} onChange={(e) => onChange(field, e.target.value)}>
        <option value="">—</option>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </div>
  );
}

export default function NouvelleFicheClient() {
  const router = useRouter();
  const [data, setData] = useState<ProductSheetData>({ ...EMPTY_SHEET });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  function set(field: Field, value: string) {
    setData((prev) => ({ ...prev, [field]: value }));
  }

  function showToast(msg: string) {
    setToast(msg);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(null), 2600);
  }

  function handleImage(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    const reader = new FileReader();
    reader.onload = (ev) => setImagePreview(ev.target?.result as string);
    reader.readAsDataURL(file);
  }

  async function handleSubmit() {
    if (!data.ref.trim()) {
      showToast("Ajoutez au moins une référence avant de générer.");
      return;
    }
    setSubmitting(true);
    try {
      const form = new FormData();
      form.append("data", JSON.stringify(data));
      if (imageFile) form.append("image", imageFile);

      const res = await fetch("/api/product-sheets", { method: "POST", body: form });
      const json = await res.json();
      if (!res.ok) {
        showToast(json.error || "Erreur lors de la génération de la fiche.");
        setSubmitting(false);
        return;
      }
      showToast(`Fiche « ${data.ref} » ajoutée au répertoire.`);
      router.push("/repertoire");
      router.refresh();
    } catch (e) {
      showToast(`Erreur réseau : ${(e as Error).message}`);
      setSubmitting(false);
    }
  }

  const previewData: ProductSheetData = { ...data, imageUrl: imagePreview };

  return (
    <section>
      <div className="view-head">
        <div>
          <h1>Nouvelle fiche produit</h1>
          <p>Renseignez les champs — l&apos;aperçu à droite se met à jour en direct.</p>
        </div>
      </div>

      <div className="builder">
        <div className="form-panel">
          <h2>Informations SKU</h2>
          <p className="hint">Tous les champs marqués — sont optionnels.</p>

          <form onSubmit={(e) => e.preventDefault()}>
            <div className="fgroup">
              <div className="fgroup-title">Identification</div>
              <div className="frow single">
                <Text label="Référence MBA Green" field="ref" placeholder="BOXFRIES01ORG" value={data.ref} onChange={set} />
              </div>
              <div className="frow single">
                <Text label="Nom produit (FR)" field="nameFr" placeholder="Boîte frites blanche bristol organic" value={data.nameFr} onChange={set} />
              </div>
              <div className="frow single">
                <Text label="Nom produit (EN)" field="nameEn" placeholder="Fries box white bristol organic" value={data.nameEn} onChange={set} />
              </div>
              <div className="frow">
                <Text label="EAN carton" field="eanBox" placeholder="3760355538791" value={data.eanBox} onChange={set} />
                <Text label="EAN UVC" field="eanUvc" placeholder="3760355538791" value={data.eanUvc} onChange={set} />
              </div>
              <div className="frow single">
                <Text label="Code douanier" field="customCode" placeholder="48193000" value={data.customCode} onChange={set} />
              </div>
              <div className="frow single">
                <Select
                  label="Catégorie produit"
                  field="category"
                  options={PRODUCT_CATEGORIES}
                  value={data.category}
                  onChange={set}
                />
              </div>
            </div>

            <div className="fgroup">
              <div className="fgroup-title">Caractéristiques produit</div>
              <div className="frow">
                <Text label="Matière" field="material" placeholder="Paper 250 GSM" value={data.material} onChange={set} />
                <Text label="Capacité" field="capacity" placeholder="—" value={data.capacity} onChange={set} />
              </div>
              <div className="frow">
                <Text label="Hauteur" field="height" placeholder="45mm" value={data.height} onChange={set} />
                <Text label="Diamètre" field="diameter" placeholder="—" value={data.diameter} onChange={set} />
              </div>
              <div className="frow">
                <Text label="Longueur" field="length" placeholder="90mm" value={data.length} onChange={set} />
                <Text label="Gusset" field="gusset" placeholder="—" value={data.gusset} onChange={set} />
              </div>
              <div className="frow">
                <Text label="Largeur" field="width" placeholder="145mm" value={data.width} onChange={set} />
                <Text label="Poids net" field="netWeight" placeholder="15 GR" value={data.netWeight} onChange={set} />
              </div>
            </div>

            <div className="fgroup">
              <div className="fgroup-title">UVC — Unité de vente</div>
              <div className="frow">
                <Text label="Pièces / UVC" field="unitsPerUvc" placeholder="—" value={data.unitsPerUvc} onChange={set} />
                <Text label="Poids net UVC" field="uvcWeight" placeholder="—" value={data.uvcWeight} onChange={set} />
              </div>
            </div>

            <div className="fgroup">
              <div className="fgroup-title">Carton</div>
              <div className="frow">
                <Text label="Pièces / carton" field="unitsPerBox" placeholder="600" value={data.unitsPerBox} onChange={set} />
                <Text label="Dimensions" field="boxDim" placeholder="350x250x240mm" value={data.boxDim} onChange={set} />
              </div>
              <div className="frow">
                <Text label="Poids brut" field="boxGross" placeholder="9 kg" value={data.boxGross} onChange={set} />
                <Text label="Poids net" field="boxNet" placeholder="—" value={data.boxNet} onChange={set} />
              </div>
              <div className="frow single">
                <Text label="Volume" field="boxVolume" placeholder="—" value={data.boxVolume} onChange={set} />
              </div>
            </div>

            <div className="fgroup">
              <div className="fgroup-title">Palette</div>
              <div className="frow">
                <Text label="Pièces / palette" field="unitsPerPallet" placeholder="37800" value={data.unitsPerPallet} onChange={set} />
                <Text label="Cartons / palette" field="boxesPerPallet" placeholder="63" value={data.boxesPerPallet} onChange={set} />
              </div>
              <div className="frow">
                <Text label="Couches / palette" field="layersPerPallet" placeholder="7" value={data.layersPerPallet} onChange={set} />
                <Text label="Cartons / couche" field="boxesPerLayer" placeholder="9" value={data.boxesPerLayer} onChange={set} />
              </div>
              <div className="frow">
                <Text label="Hauteur palette" field="palletHeight" placeholder="1,8 m" value={data.palletHeight} onChange={set} />
                <Text label="Poids palette" field="palletWeight" placeholder="567 kg" value={data.palletWeight} onChange={set} />
              </div>
              <div className="frow single">
                <Text label="Volume palette" field="palletVolume" placeholder="—" value={data.palletVolume} onChange={set} />
              </div>
            </div>

            <div className="fgroup">
              <div className="fgroup-title">Tolérance &amp; visuel</div>
              <div className="frow single">
                <Text label="Tolérance" field="tolerance" placeholder="10 %" value={data.tolerance} onChange={set} />
              </div>
              <div className="frow single">
                <div>
                  <label>Visuel produit</label>
                  <div className="imgpick">
                    {imagePreview ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={imagePreview} alt="Aperçu visuel" />
                    ) : (
                      <span>Cliquer pour importer une image</span>
                    )}
                    <input type="file" accept="image/*" onChange={handleImage} />
                  </div>
                </div>
              </div>
            </div>

            <button type="button" className="genbtn" onClick={handleSubmit} disabled={submitting}>
              {submitting ? "Génération en cours…" : "Générer la fiche PDF"}
            </button>
          </form>
        </div>

        <div>
          <div className="preview-shell">
            <div className="sheet-scale-wrap">
              <LivePreview data={previewData} />
            </div>
          </div>
          <div className="preview-actions">
            <button className="btn primary" onClick={handleSubmit} disabled={submitting}>
              {submitting ? "Enregistrement…" : "Enregistrer & ajouter au répertoire"}
            </button>
          </div>
        </div>
      </div>

      <div className={`toast ${toast ? "show" : ""}`}>{toast}</div>
    </section>
  );
}

function LivePreview({ data }: { data: ProductSheetData }) {
  return (
    <div
      style={{ width: "100%", height: "100%", position: "relative" }}
      ref={(el) => {
        if (!el) return;
        const inner = el.firstElementChild as HTMLElement | null;
        if (!inner) return;
        const scale = el.clientWidth / 794;
        inner.style.transform = `scale(${scale})`;
      }}
    >
      <div style={{ width: 794, height: 1123, transformOrigin: "top left" }}>
        <ProductSheetView data={data} />
      </div>
    </div>
  );
}
FILEEOF

mkdir -p src/components
cat > src/components/RepertoireClient.tsx <<'FILEEOF'
"use client";

import { useMemo, useState } from "react";
import { materialFamily, type ProductSheetData } from "@/lib/types";
import ProductSheetView from "@/components/ProductSheetView";
import ProductDocuments from "@/components/ProductDocuments";

// Bulk-imported sheets link to the client's original Drive-hosted datasheet
// PDF (pdf_url pointing at drive.google.com) rather than one we generated.
// For those, show the actual original PDF as the preview instead of the
// live A4 mockup (which is built from structured fields that are often
// left blank for imported SKUs).
function driveEmbedUrl(url: string | null | undefined): string | null {
  if (!url) return null;
  const match = url.match(/drive\.google\.com\/file\/d\/([^/]+)/);
  if (!match) return null;
  return `https://drive.google.com/file/d/${match[1]}/preview`;
}

export default function RepertoireClient({
  initialSheets,
  loadError,
}: {
  initialSheets: ProductSheetData[];
  loadError: string | null;
}) {
  const [sheets] = useState(initialSheets);
  const [search, setSearch] = useState("");
  const [activeChip, setActiveChip] = useState("Toutes");
  const [modalSheet, setModalSheet] = useState<ProductSheetData | null>(null);

  const families = useMemo(() => {
    const set = new Set(sheets.map((s) => materialFamily(s.material)));
    return ["Toutes", ...Array.from(set)];
  }, [sheets]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return sheets.filter((s) => {
      const matchesChip = activeChip === "Toutes" || materialFamily(s.material) === activeChip;
      if (!matchesChip) return false;
      if (!q) return true;
      const hay = [s.ref, s.nameFr, s.nameEn, s.eanBox, s.eanUvc, s.material].join(" ").toLowerCase();
      return hay.includes(q);
    });
  }, [sheets, search, activeChip]);

  return (
    <section>
      <div className="view-head">
        <div>
          <h1>Répertoire des fiches produit</h1>
          <p>— {sheets.length} SKU indexés</p>
        </div>
        <div className="searchbar">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
            <circle cx="11" cy="11" r="7" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            type="text"
            placeholder="Rechercher par référence, nom, EAN, matière…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div className="chipbar">
        {families.map((f) => (
          <button
            key={f}
            className={`chip ${f === activeChip ? "active" : ""}`}
            onClick={() => setActiveChip(f)}
          >
            {f}
          </button>
        ))}
      </div>

      <div className="result-count">
        {loadError
          ? `Erreur de chargement : ${loadError}`
          : `${filtered.length} ${filtered.length > 1 ? "fiches trouvées" : "fiche trouvée"}`}
      </div>

      {filtered.length === 0 ? (
        <div className="empty">
          <b>Aucun résultat</b>
          Essayez une autre référence, un autre EAN ou une autre matière.
        </div>
      ) : (
        <div className="list">
          <div className="list-row list-row-head">
            <div className="col-ref">Référence</div>
            <div className="col-name">Désignation</div>
            <div className="col-ean">EAN carton</div>
            <div className="col-material">Matière</div>
            <div className="col-arrow" />
          </div>
          {filtered.map((s) => (
            <div className="list-row" key={s.id ?? s.ref} onClick={() => setModalSheet(s)}>
              <div className="col-ref">{s.ref}</div>
              <div className="col-name">{s.nameFr}</div>
              <div className="col-ean">{s.eanBox || "—"}</div>
              <div className="col-material">{s.material}</div>
              <div className="col-arrow">→</div>
            </div>
          ))}
        </div>
      )}

      {modalSheet && (
        <div
          className="modal-bg"
          onClick={(e) => {
            if (e.target === e.currentTarget) setModalSheet(null);
          }}
        >
          <div className="modal-card">
            <div className="modal-close">
              <button onClick={() => setModalSheet(null)}>✕</button>
            </div>
            <div className="sheet-scale-wrap">
              {driveEmbedUrl(modalSheet.pdfUrl) ? (
                <iframe
                  src={driveEmbedUrl(modalSheet.pdfUrl) ?? undefined}
                  className="original-pdf-frame"
                  title={`Datasheet originale ${modalSheet.ref}`}
                />
              ) : (
                <ScaledSheet data={modalSheet} />
              )}
            </div>
            <div className="preview-actions">
              {modalSheet.pdfUrl ? (
                <a className="btn primary" href={modalSheet.pdfUrl} target="_blank" rel="noopener noreferrer">
                  Télécharger le PDF
                </a>
              ) : (
                <span className="btn primary" style={{ opacity: 0.6, cursor: "default" }}>
                  PDF indisponible
                </span>
              )}
              <a
                className="btn"
                href={`/api/sticker?ref=${encodeURIComponent(modalSheet.ref)}`}
                target="_blank"
                rel="noopener noreferrer"
              >
                Télécharger le sticker
              </a>
            </div>
            <ProductDocuments skuRef={modalSheet.ref} />
          </div>
        </div>
      )}
    </section>
  );
}

// Scales the fixed 794x1123 (A4 @ 96dpi) .sheet down to fit its wrapper,
// same trick as the prototype's scaleSheet().
function ScaledSheet({ data }: { data: ProductSheetData }) {
  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        position: "relative",
      }}
    >
      <div
        style={{
          width: 794,
          height: 1123,
          transform: "scale(var(--scale, 0.807))",
          transformOrigin: "top left",
        }}
        ref={(el) => {
          if (!el) return;
          const wrap = el.parentElement;
          if (!wrap) return;
          const scale = wrap.clientWidth / 794;
          el.style.setProperty("--scale", String(scale));
          el.style.transform = `scale(${scale})`;
        }}
      >
        <ProductSheetView data={data} />
      </div>
    </div>
  );
}

FILEEOF

mkdir -p src/app/api/sticker
cat > src/app/api/sticker/route.ts <<'FILEEOF'
import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabaseAdmin";
import { rowToSheet, type ProductSheetRow } from "@/lib/types";
import { generateStickerPdf } from "@/lib/stickerPdf";

export const runtime = "nodejs";
export const maxDuration = 30;

// GET /api/sticker?ref=<sku ref>
// Generates the printable carton sticker (SKU, EAN13 + barcode, items per
// pack, product dimensions, category icon) on the fly from the sheet's own
// structured fields — nothing is stored, it's rendered fresh on every call.
export async function GET(req: NextRequest) {
  const ref = req.nextUrl.searchParams.get("ref")?.trim() ?? "";
  if (!ref) {
    return NextResponse.json({ error: "Paramètre 'ref' manquant." }, { status: 400 });
  }

  const supabase = supabaseAdmin();
  const { data, error } = await supabase
    .from("product_sheets")
    .select("*")
    .eq("ref", ref)
    .maybeSingle();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  if (!data) {
    return NextResponse.json({ error: `Aucune fiche trouvée pour "${ref}".` }, { status: 404 });
  }

  const sheet = rowToSheet(data as ProductSheetRow);

  try {
    const pdf = await generateStickerPdf(sheet);
    return new NextResponse(new Uint8Array(pdf), {
      status: 200,
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": `attachment; filename="Sticker-${ref}.pdf"`,
      },
    });
  } catch (e) {
    return NextResponse.json(
      { error: `Échec de la génération du sticker: ${(e as Error).message}` },
      { status: 500 }
    );
  }
}
FILEEOF

git add -A
git status
echo "Done. Review the diff, then: git commit -m \"Add carton sticker generation feature\" && git push"
