#!/bin/bash
set -e
echo "Applying: sticker text/dims fixes + repertoire download fallbacks..."

cat > src/lib/stickerHtml.ts <<'FILEEOF'
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
FILEEOF

cat > src/components/RepertoireClient.tsx <<'FILEEOF'
"use client";

import { useMemo, useState } from "react";
import { materialFamily, type ProductSheetData } from "@/lib/types";
import ProductSheetView from "@/components/ProductSheetView";
import ProductDocuments from "@/components/ProductDocuments";

export interface RepertoireDoc {
  category: string;
  fileName: string;
  url: string;
}

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

// BAT and stickers were never given their own category (see documentTypes.ts
// — everything that isn't a datasheet/die cut/carton design falls under
// "other"), so they're told apart here by keyword in the file name instead,
// matching how the client actually names these files ("... BAT.pdf",
// "... Sticker.pdf").
function findDoc(
  docs: RepertoireDoc[] | undefined,
  predicate: (d: RepertoireDoc) => boolean
): RepertoireDoc | undefined {
  return docs?.find(predicate);
}

function docLinksFor(
  docs: RepertoireDoc[] | undefined,
  sheet: ProductSheetData
): {
  datasheet: RepertoireDoc | undefined;
  dieCut: RepertoireDoc | undefined;
  carton: RepertoireDoc | undefined;
  bat: RepertoireDoc | undefined;
  sticker: RepertoireDoc | undefined;
} {
  const uploadedDatasheet = findDoc(docs, (d) => d.category === "technical_data_sheet");
  const uploadedSticker = findDoc(docs, (d) => d.category === "other" && /sticker/i.test(d.fileName));

  return {
    // Bulk-imported SKUs have the client's original datasheet filed as a
    // document; SKUs created straight in the app don't have one uploaded,
    // but always have the auto-generated fiche PDF (pdf_url) — fall back to
    // that so the column never sits empty for a sheet that clearly has one.
    datasheet:
      uploadedDatasheet ??
      (sheet.pdfUrl
        ? { category: "technical_data_sheet", fileName: `${sheet.ref}.pdf`, url: sheet.pdfUrl }
        : undefined),
    dieCut: findDoc(docs, (d) => d.category === "die_cut"),
    carton: findDoc(docs, (d) => d.category === "carton_design"),
    bat: findDoc(docs, (d) => d.category === "other" && /\bbat\b/i.test(d.fileName)),
    // Same idea for the sticker: prefer an uploaded original design if one
    // exists, otherwise fall back to the sticker this app can always
    // generate on demand from the sheet's own fields.
    sticker:
      uploadedSticker ??
      (sheet.eanBox
        ? { category: "other", fileName: `Sticker ${sheet.ref}.pdf`, url: `/api/sticker?ref=${encodeURIComponent(sheet.ref)}` }
        : undefined),
  };
}

function DocLink({ doc }: { doc: RepertoireDoc | undefined }) {
  if (!doc) return <span className="doc-link doc-link-empty">—</span>;
  return (
    <a
      className="doc-link"
      href={doc.url}
      target="_blank"
      rel="noopener noreferrer"
      title={doc.fileName}
      onClick={(e) => e.stopPropagation()}
    >
      ↓
    </a>
  );
}

export default function RepertoireClient({
  initialSheets,
  loadError,
  documentsByRef,
}: {
  initialSheets: ProductSheetData[];
  loadError: string | null;
  documentsByRef?: Record<string, RepertoireDoc[]>;
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
    return sheets
      .filter((s) => {
        const matchesChip = activeChip === "Toutes" || materialFamily(s.material) === activeChip;
        if (!matchesChip) return false;
        if (!q) return true;
        const hay = [s.ref, s.nameFr, s.nameEn, s.eanBox, s.eanUvc, s.material].join(" ").toLowerCase();
        return hay.includes(q);
      })
      .sort((a, b) => a.ref.localeCompare(b.ref, undefined, { numeric: true, sensitivity: "base" }));
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
            <div className="col-doc">Datasheet</div>
            <div className="col-doc">Die cut</div>
            <div className="col-doc">Carton</div>
            <div className="col-doc">BAT</div>
            <div className="col-doc">Sticker</div>
            <div className="col-arrow" />
          </div>
          {filtered.map((s) => {
            const links = docLinksFor(documentsByRef?.[s.ref], s);
            return (
              <div className="list-row" key={s.id ?? s.ref} onClick={() => setModalSheet(s)}>
                <div className="col-ref">{s.ref}</div>
                <div className="col-name">{s.nameFr}</div>
                <div className="col-ean">{s.eanBox || "—"}</div>
                <div className="col-material">{s.material}</div>
                <div className="col-doc"><DocLink doc={links.datasheet} /></div>
                <div className="col-doc"><DocLink doc={links.dieCut} /></div>
                <div className="col-doc"><DocLink doc={links.carton} /></div>
                <div className="col-doc"><DocLink doc={links.bat} /></div>
                <div className="col-doc"><DocLink doc={links.sticker} /></div>
                <div className="col-arrow">→</div>
              </div>
            );
          })}
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

git add -A
git status
echo "Done. Review the diff, then: git commit -m \"Fix sticker text overflow/dims, add datasheet+sticker fallback links\" && git push"
