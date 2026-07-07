#!/bin/bash
set -e
echo "Applying: alphabetical sort + document link columns in repertoire..."

cat > src/app/repertoire/page.tsx <<'FILEEOF'
import { supabaseAdmin, PRODUCT_DOCUMENTS_BUCKET } from "@/lib/supabaseAdmin";
import { rowToSheet, type ProductSheetRow } from "@/lib/types";
import type { ProductDocumentRow } from "@/lib/documentTypes";
import RepertoireClient, { type RepertoireDoc } from "@/components/RepertoireClient";

export const dynamic = "force-dynamic";

export default async function RepertoirePage() {
  const supabase = supabaseAdmin();
  const { data, error } = await supabase
    .from("product_sheets")
    .select("*")
    .order("created_at", { ascending: false });

  const sheets = error ? [] : (data as ProductSheetRow[]).map(rowToSheet);

  // Also fetch every extra document (datasheet, die cut, carton design, BAT,
  // sticker...) so the répertoire table can link straight to them instead of
  // making people open each fiche to find them.
  const { data: docsData } = await supabase
    .from("product_documents")
    .select("*")
    .order("uploaded_at", { ascending: true });

  const documentsByRef: Record<string, RepertoireDoc[]> = {};
  for (const row of (docsData ?? []) as ProductDocumentRow[]) {
    const isExternal = row.storage_path.startsWith("http://") || row.storage_path.startsWith("https://");
    const url = isExternal
      ? row.storage_path
      : supabase.storage.from(PRODUCT_DOCUMENTS_BUCKET).getPublicUrl(row.storage_path).data.publicUrl;
    (documentsByRef[row.ref] ??= []).push({
      category: row.category,
      fileName: row.file_name,
      url,
    });
  }

  return (
    <RepertoireClient
      initialSheets={sheets}
      loadError={error?.message ?? null}
      documentsByRef={documentsByRef}
    />
  );
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

function docLinksFor(docs: RepertoireDoc[] | undefined) {
  return {
    datasheet: findDoc(docs, (d) => d.category === "technical_data_sheet"),
    dieCut: findDoc(docs, (d) => d.category === "die_cut"),
    carton: findDoc(docs, (d) => d.category === "carton_design"),
    bat: findDoc(docs, (d) => d.category === "other" && /\bbat\b/i.test(d.fileName)),
    sticker: findDoc(docs, (d) => d.category === "other" && /sticker/i.test(d.fileName)),
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
            const links = docLinksFor(documentsByRef?.[s.ref]);
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

cat > src/app/globals.css <<'FILEEOF'
:root{
  --sage:#a8a98d;
  --sage-dark:#93947a;
  --deepgreen:#2f4738;
  --deepgreen-2:#3d5a48;
  --cream:#f4f2ea;
  --paper:#ffffff;
  --ink:#2a2a24;
  --ink-soft:#75745f;
  --line:#dddac9;
  --peach:#dfa276;
  --shadow: 0 1px 2px rgba(42,42,36,.06), 0 6px 20px rgba(42,42,36,.06);
}
*{box-sizing:border-box; margin:0; padding:0;}
html,body{margin:0;padding:0; height:100%;}
body{
  background:var(--cream);
  color:var(--ink);
  font-family:var(--font-inter), 'Inter', sans-serif;
  -webkit-font-smoothing:antialiased;
}
a{color:inherit; text-decoration:none;}
.wordmark{font-family:var(--font-space-grotesk), 'Space Grotesk', sans-serif;}

/* ---------- App shell ---------- */
header.appbar{
  position:sticky; top:0; z-index:20;
  background:var(--paper);
  border-bottom:1px solid var(--line);
}
.appbar-inner{
  max-width:1320px; margin:0 auto;
  display:flex; align-items:center; gap:28px;
  padding:14px 28px;
}
.brand{display:flex; align-items:center; gap:10px;}
.brand-logo{height:24px; width:auto; display:block;}
.brand-name{font-weight:600; font-size:17px; letter-spacing:.2px;}
.brand-name sup{font-size:9px; font-weight:600;}
.brand-sub{font-size:11px; color:var(--ink-soft); margin-left:2px; padding-left:12px; border-left:1px solid var(--line);}

nav.tabs{display:flex; gap:4px; margin-left:auto;}
nav.tabs a{
  font-family:'Inter',sans-serif; font-size:13.5px; font-weight:600;
  border:none; background:transparent; color:var(--ink-soft);
  padding:9px 16px; border-radius:8px; cursor:pointer;
  transition:background .15s, color .15s; display:inline-block;
}
nav.tabs a:hover{background:var(--cream); color:var(--ink);}
nav.tabs a.active{background:var(--deepgreen); color:#fff;}

main{max-width:1320px; margin:0 auto; padding:32px 28px 80px; width:100%;}

/* ---------- Repository view ---------- */
.view-head{display:flex; align-items:flex-end; justify-content:space-between; gap:24px; margin-bottom:22px; flex-wrap:wrap;}
.view-head h1{font-family:var(--font-space-grotesk), sans-serif; font-size:26px; margin:0 0 4px;}
.view-head p{margin:0; color:var(--ink-soft); font-size:13.5px;}

.searchbar{
  max-width:420px; width:100%; display:flex; align-items:center; gap:8px;
  padding:0 14px; border-radius:10px; border:1px solid var(--line); background:var(--paper);
  transition:border-color .15s, box-shadow .15s;
}
.searchbar:focus-within{border-color:var(--sage-dark); box-shadow:0 0 0 3px rgba(168,169,141,.25);}
.searchbar svg{opacity:.5; flex-shrink:0;}
.searchbar input{
  width:100%; padding:11px 0; border:none; background:transparent;
  font-family:'Inter',sans-serif; font-size:14px; color:var(--ink);
  outline:none;
}

.chipbar{display:flex; gap:8px; margin:16px 0 22px; flex-wrap:wrap;}
.chip{
  font-size:12.5px; font-weight:600; padding:6px 13px; border-radius:999px;
  border:1px solid var(--line); background:var(--paper); color:var(--ink-soft);
  cursor:pointer; transition:all .15s;
}
.chip.active{background:var(--deepgreen); border-color:var(--deepgreen); color:#fff;}
.chip:hover:not(.active){border-color:var(--sage-dark); color:var(--ink);}

.result-count{font-size:12.5px; color:var(--ink-soft); margin-bottom:14px;}

.list{ border:1px solid var(--line); border-radius:12px; overflow:hidden; background:var(--paper); }
.list-row{
  display:grid;
  grid-template-columns:130px 1fr 120px 110px 68px 60px 60px 50px 60px 20px;
  gap:12px; align-items:center;
  padding:13px 16px; border-bottom:1px solid var(--line);
}
.list-row:last-child{border-bottom:none;}
.list-row:not(.list-row-head){cursor:pointer; transition:background .15s;}
.list-row:not(.list-row-head):hover{background:var(--cream);}
.list-row-head{
  background:var(--sage); padding:11px 16px;
  font-size:11px; text-transform:uppercase; letter-spacing:.4px; font-weight:600; color:var(--deepgreen);
}
.list-row .col-ref{
  font-family:var(--font-space-grotesk), sans-serif; font-weight:600; font-size:13px;
  color:var(--deepgreen); letter-spacing:.2px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;
}
.list-row .col-name{font-weight:600; font-size:13.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;}
.list-row-head .col-name{font-weight:600;}
.list-row:not(.list-row-head) .col-ean{font-size:12.5px; color:var(--ink-soft);}
.list-row:not(.list-row-head) .col-material{font-size:12px; color:var(--ink-soft); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;}
.list-row:not(.list-row-head) .col-arrow{font-size:15px; color:var(--deepgreen); text-align:right;}
.list-row-head .col-arrow{visibility:hidden;}
.list-row .col-doc{text-align:center;}
.doc-link{
  display:inline-flex; align-items:center; justify-content:center;
  width:26px; height:26px; border-radius:6px; font-size:13px; font-weight:700;
  color:var(--deepgreen); background:var(--cream); border:1px solid var(--line);
  transition:background .15s, border-color .15s;
}
.doc-link:hover{background:var(--sage); border-color:var(--sage-dark);}
.doc-link-empty{
  display:inline-block; color:var(--ink-soft); background:none; border:none; width:auto; height:auto; font-weight:400;
}

.empty{ text-align:center; padding:70px 20px; color:var(--ink-soft); }
.empty b{display:block; color:var(--ink); font-size:16px; margin-bottom:6px;}

/* ---------- New sheet view ---------- */
.builder{display:grid; grid-template-columns:minmax(320px,420px) 1fr; gap:28px; align-items:flex-start;}
@media (max-width:920px){ .builder{grid-template-columns:1fr;} }

.form-panel{
  background:var(--paper); border:1px solid var(--line); border-radius:14px; padding:22px;
  position:sticky; top:88px; max-height:calc(100vh - 110px); overflow:auto;
}
.form-panel h2{font-family:var(--font-space-grotesk), sans-serif; font-size:16px; margin:0 0 4px;}
.form-panel .hint{font-size:12px; color:var(--ink-soft); margin:0 0 18px;}

.fgroup{margin-bottom:18px;}
.fgroup-title{
  font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.5px;
  color:var(--deepgreen); border-bottom:1px solid var(--line); padding-bottom:6px; margin-bottom:10px;
}
.frow{display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-bottom:8px;}
.frow.single{grid-template-columns:1fr;}
label{font-size:11.5px; color:var(--ink-soft); display:block; margin-bottom:3px; font-weight:500;}
input[type=text], input[type=number], textarea, select{
  width:100%; padding:8px 10px; border:1px solid var(--line); border-radius:7px;
  font-family:'Inter',sans-serif; font-size:13px; color:var(--ink); background:var(--cream);
  outline:none; transition:border-color .15s, background .15s;
}
input:focus, textarea:focus, select:focus{border-color:var(--sage-dark); background:var(--paper);}
textarea{resize:vertical; min-height:40px;}

.imgpick{
  border:1.5px dashed var(--line); border-radius:9px; padding:14px; text-align:center;
  cursor:pointer; font-size:12px; color:var(--ink-soft); position:relative; overflow:hidden;
}
.imgpick img{max-width:100%; max-height:90px; display:block; margin:0 auto;}
.imgpick input{position:absolute; inset:0; opacity:0; cursor:pointer;}

.genbtn{
  width:100%; margin-top:6px; padding:12px; border:none; border-radius:9px;
  background:var(--deepgreen); color:#fff; font-family:'Inter',sans-serif;
  font-size:14px; font-weight:700; cursor:pointer; transition:background .15s;
}
.genbtn:hover{background:#26382c;}
.genbtn:disabled{opacity:.6; cursor:default;}

/* ---------- Sheet preview wrapper (the .sheet itself is in sheetCss.ts) ---------- */
.preview-shell{display:flex; justify-content:center;}
.sheet-scale-wrap{
  width:100%; max-width:640px; aspect-ratio:210/297; position:relative;
  box-shadow:var(--shadow); border-radius:2px; overflow:hidden;
}
.sheet-scale-wrap .sheet{
  position:absolute; top:0; left:0; transform-origin:top left;
}

.sheet-scale-wrap iframe.original-pdf-frame{
  position:absolute; top:0; left:0; width:100%; height:100%; border:none; background:#fff;
}

.preview-actions{display:flex; justify-content:center; gap:10px; margin-top:16px;}
.btn{
  padding:9px 16px; border-radius:8px; font-size:13px; font-weight:600; cursor:pointer;
  border:1px solid var(--line); background:var(--paper); color:var(--ink); transition:all .15s;
}
.btn.primary{background:var(--deepgreen); border-color:var(--deepgreen); color:#fff;}
.btn:hover{border-color:var(--sage-dark);}
.btn.primary:hover{background:#26382c;}
.btn:disabled{opacity:.6; cursor:default;}

/* ---------- Modal ---------- */
.modal-bg{
  position:fixed; inset:0; background:rgba(42,42,36,.45); display:flex;
  align-items:flex-start; justify-content:center; padding:40px 20px; overflow:auto; z-index:100;
}
.modal-card{background:transparent; width:100%; max-width:640px;}
.modal-close{display:flex; justify-content:flex-end; margin-bottom:10px;}
.modal-close button{
  background:var(--paper); border:1px solid var(--line); border-radius:8px; width:34px; height:34px;
  cursor:pointer; font-size:16px; color:var(--ink-soft);
}

.toast{
  position:fixed; bottom:24px; left:50%; transform:translateX(-50%) translateY(20px);
  background:var(--deepgreen); color:#fff; padding:12px 20px; border-radius:9px;
  font-size:13px; font-weight:600; opacity:0; pointer-events:none; transition:all .25s;
  z-index:200;
}
.toast.show{opacity:1; transform:translateX(-50%) translateY(0);}

/* ---------- Product documents panel (in the repertoire modal) ---------- */
.docs-panel{
  margin-top: 22px; background: var(--paper); border: 1px solid var(--line);
  border-radius: 14px; padding: 20px;
}
.docs-title{ font-family: var(--font-space-grotesk), sans-serif; font-size: 15px; margin: 0 0 4px; }
.docs-hint{ font-size: 12px; color: var(--ink-soft); margin: 0 0 14px; }

.docs-upload-row{ display: flex; gap: 10px; margin-bottom: 14px; flex-wrap: wrap; }
.docs-category-select{
  padding: 9px 10px; border: 1px solid var(--line); border-radius: 8px;
  font-family: 'Inter', sans-serif; font-size: 12.5px; color: var(--ink); background: var(--cream);
  outline: none; flex: 0 0 auto;
}
.docs-dropzone{
  flex: 1 1 220px; min-width: 200px; border: 1.5px dashed var(--line); border-radius: 9px;
  padding: 12px 14px; text-align: center; cursor: pointer; font-size: 12px; color: var(--ink-soft);
  transition: border-color .15s, background .15s;
}
.docs-dropzone:hover, .docs-dropzone.active{ border-color: var(--sage-dark); background: var(--cream); }

.docs-message{ font-size: 12px; color: #a8433a; margin-bottom: 12px; }

.docs-groups{ display: flex; flex-direction: column; gap: 14px; }
.docs-group-title{
  font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .4px;
  color: var(--deepgreen); border-bottom: 1px solid var(--line); padding-bottom: 6px; margin-bottom: 8px;
}
.docs-count{ color: var(--ink-soft); font-weight: 500; text-transform: none; letter-spacing: 0; }
.docs-empty{ font-size: 12px; color: var(--ink-soft); }

.docs-list{ list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; }
.docs-item{
  display: flex; align-items: center; gap: 10px; font-size: 12.5px;
  padding: 7px 10px; border: 1px solid var(--line); border-radius: 7px; background: #faf9f4;
}
.docs-item-name{ flex: 1; color: var(--ink); font-weight: 600; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.docs-item-meta{ color: var(--ink-soft); font-size: 11px; flex-shrink: 0; }
.docs-item-delete{
  border: none; background: transparent; color: var(--ink-soft); cursor: pointer;
  font-size: 12px; padding: 2px 6px; border-radius: 5px; flex-shrink: 0;
}
.docs-item-delete:hover{ background: var(--cream); color: #a8433a; }

FILEEOF

git add -A
git status
echo "Done. Review the diff, then: git commit -m \"Sort repertoire alphabetically, add document link columns\" && git push"
