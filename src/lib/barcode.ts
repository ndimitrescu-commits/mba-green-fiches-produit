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
