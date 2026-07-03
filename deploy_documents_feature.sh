#!/bin/bash
set -e
echo "Application des fichiers pour la fonctionnalite Documents..."
mkdir -p src/app/api/product-documents

cat > src/app/globals.css <<'MBA_EOF_0'
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

.searchbar{ position:relative; max-width:420px; width:100%; }
.searchbar input{
  width:100%; padding:11px 14px 11px 38px; border-radius:10px;
  border:1px solid var(--line); background:var(--paper);
  font-family:'Inter',sans-serif; font-size:14px; color:var(--ink);
  outline:none; transition:border-color .15s, box-shadow .15s;
}
.searchbar input:focus{border-color:var(--sage-dark); box-shadow:0 0 0 3px rgba(168,169,141,.25);}
.searchbar svg{position:absolute; left:12px; top:50%; transform:translateY(-50%); opacity:.5;}

.chipbar{display:flex; gap:8px; margin:16px 0 22px; flex-wrap:wrap;}
.chip{
  font-size:12.5px; font-weight:600; padding:6px 13px; border-radius:999px;
  border:1px solid var(--line); background:var(--paper); color:var(--ink-soft);
  cursor:pointer; transition:all .15s;
}
.chip.active{background:var(--deepgreen); border-color:var(--deepgreen); color:#fff;}
.chip:hover:not(.active){border-color:var(--sage-dark); color:var(--ink);}

.result-count{font-size:12.5px; color:var(--ink-soft); margin-bottom:14px;}

.grid{ display:grid; grid-template-columns:repeat(auto-fill, minmax(258px,1fr)); gap:16px; }
.card{
  background:var(--paper); border:1px solid var(--line); border-radius:12px;
  overflow:hidden; cursor:pointer; transition:transform .15s, box-shadow .15s;
  display:flex; flex-direction:column;
}
.card:hover{transform:translateY(-2px); box-shadow:var(--shadow);}
.card-head{ background:var(--sage); padding:12px 14px; display:flex; align-items:center; gap:8px; }
.card-head .dot{width:8px;height:8px;border-radius:50%;background:var(--deepgreen); flex-shrink:0;}
.card-head .ref{font-family:var(--font-space-grotesk), sans-serif; font-weight:600; font-size:12.5px; color:var(--deepgreen); letter-spacing:.3px;}
.card-body{padding:14px; flex:1; display:flex; flex-direction:column; gap:8px;}
.card-title{font-weight:600; font-size:14px; line-height:1.3;}
.card-meta{font-size:12px; color:var(--ink-soft); display:flex; flex-direction:column; gap:3px;}
.card-meta span b{color:var(--ink); font-weight:600;}
.card-foot{ padding:10px 14px; border-top:1px solid var(--line); display:flex; justify-content:space-between; align-items:center; }
.card-foot .material{font-size:11px; text-transform:uppercase; letter-spacing:.4px; color:var(--ink-soft); font-weight:600;}
.card-foot .arrow{font-size:16px; color:var(--deepgreen);}

.empty{ text-align:center; padding:70px 20px; color:var(--ink-soft); grid-column:1/-1; }
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

MBA_EOF_0

cat > src/components/RepertoireClient.tsx <<'MBA_EOF_1'
"use client";

import { useMemo, useState } from "react";
import { materialFamily, type ProductSheetData } from "@/lib/types";
import ProductSheetView from "@/components/ProductSheetView";
import ProductDocuments from "@/components/ProductDocuments";

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

      <div className="grid">
        {filtered.length === 0 ? (
          <div className="empty">
            <b>Aucun résultat</b>
            Essayez une autre référence, un autre EAN ou une autre matière.
          </div>
        ) : (
          filtered.map((s) => (
            <div className="card" key={s.id ?? s.ref} onClick={() => setModalSheet(s)}>
              <div className="card-head">
                <div className="dot" />
                <div className="ref">{s.ref}</div>
              </div>
              <div className="card-body">
                <div className="card-title">{s.nameFr}</div>
                <div className="card-meta">
                  <span>
                    EAN carton — <b>{s.eanBox || "—"}</b>
                  </span>
                  <span>
                    Dimensions carton — <b>{s.boxDim || "—"}</b>
                  </span>
                </div>
              </div>
              <div className="card-foot">
                <div className="material">{s.material}</div>
                <div className="arrow">→</div>
              </div>
            </div>
          ))
        )}
      </div>

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
              <ScaledSheet data={modalSheet} />
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

MBA_EOF_1

cat > src/lib/supabaseAdmin.ts <<'MBA_EOF_2'
import "server-only";
import { createClient } from "@supabase/supabase-js";

// Server-side Supabase client, used only from Route Handlers / Server
// Components (never imported into client components).
//
// This is an internal tool with no separate end-user auth system in scope
// for V1 (see brief). Rather than wire in a service-role secret key (which
// would need to be typed in by hand and kept out of source control), we use
// the anon/publishable key plus explicit RLS policies on product_sheets and
// the two storage buckets that grant the `anon` role read/write access. If
// user auth is introduced later, tighten those policies and switch this to
// a service-role key kept in Vercel's encrypted env vars.
let cached: ReturnType<typeof createClient> | null = null;

export function supabaseAdmin() {
  if (cached) return cached;

  const url = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables.");
  }

  cached = createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return cached;
}

export const PRODUCT_IMAGES_BUCKET = "product-images";
export const PRODUCT_PDFS_BUCKET = "product-sheet-pdfs";
export const PRODUCT_DOCUMENTS_BUCKET = "product-documents";

MBA_EOF_2

cat > src/lib/documentTypes.ts <<'MBA_EOF_3'
// Data shapes for extra product documents (die cuts, carton designs,
// technical data sheets, etc.) attached to a product sheet (SKU).
//
// Unlike ProductSheetData, these files are never generated by the app —
// they are existing files the user already has and just wants to store and
// retrieve, organized by category, per SKU.

export type DocumentCategory =
  | "technical_data_sheet"
  | "die_cut"
  | "carton_design"
  | "other";

export const DOCUMENT_CATEGORIES: { value: DocumentCategory; label: string }[] = [
  { value: "technical_data_sheet", label: "Technical data sheet" },
  { value: "die_cut", label: "Die cut" },
  { value: "carton_design", label: "Design carton" },
  { value: "other", label: "Autre" },
];

export function categoryLabel(category: string): string {
  return DOCUMENT_CATEGORIES.find((c) => c.value === category)?.label ?? category;
}

export interface ProductDocumentData {
  id: string;
  ref: string;
  category: DocumentCategory;
  fileName: string;
  url: string;
  mimeType: string | null;
  fileSize: number | null;
  uploadedAt: string;
}

// Row shape as stored in the Supabase `product_documents` table (snake_case).
export interface ProductDocumentRow {
  id: string;
  ref: string;
  category: string;
  file_name: string;
  storage_path: string;
  mime_type: string | null;
  file_size: number | null;
  uploaded_at: string;
}

export function rowToDocument(row: ProductDocumentRow, publicUrl: string): ProductDocumentData {
  return {
    id: row.id,
    ref: row.ref,
    category: row.category as DocumentCategory,
    fileName: row.file_name,
    url: publicUrl,
    mimeType: row.mime_type,
    fileSize: row.file_size,
    uploadedAt: row.uploaded_at,
  };
}

MBA_EOF_3

cat > src/components/ProductDocuments.tsx <<'MBA_EOF_4'
"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  DOCUMENT_CATEGORIES,
  type DocumentCategory,
  type ProductDocumentData,
} from "@/lib/documentTypes";

const ACCEPT =
  ".pdf,.png,.jpg,.jpeg,.webp,.gif,.ai,.eps,.dwg,.dxf,.zip,application/pdf,image/*";

function formatSize(bytes: number | null): string {
  if (!bytes) return "";
  if (bytes < 1024) return `${bytes} o`;
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} Ko`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} Mo`;
}

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString("fr-FR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
  } catch {
    return "";
  }
}

// Pure fetch helper (no setState) so it can be safely called both from the
// mount effect and from event handlers without tripping the
// react-hooks/set-state-in-effect rule.
async function fetchDocuments(skuRef: string): Promise<ProductDocumentData[]> {
  const res = await fetch(`/api/product-documents?ref=${encodeURIComponent(skuRef)}`);
  const json = await res.json();
  if (!res.ok) throw new Error(json.error || "Erreur de chargement.");
  return json.documents ?? [];
}

/**
 * "Documents" panel attached to a product sheet (SKU): lets the user file
 * away and retrieve extra documents (die cuts, carton designs, technical
 * data sheets, etc.) that already exist and are never generated by the
 * app — just uploaded, categorized, and stored per SKU.
 */
export default function ProductDocuments({ skuRef }: { skuRef: string }) {
  const [documents, setDocuments] = useState<ProductDocumentData[]>([]);
  const [loading, setLoading] = useState(true);
  const [category, setCategory] = useState<DocumentCategory>("technical_data_sheet");
  const [dragActive, setDragActive] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    let cancelled = false;
    fetchDocuments(skuRef)
      .then((docs) => {
        if (!cancelled) setDocuments(docs);
      })
      .catch((e: Error) => {
        if (!cancelled) setMessage(e.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [skuRef]);

  const reload = useCallback(async () => {
    try {
      setDocuments(await fetchDocuments(skuRef));
    } catch (e) {
      setMessage((e as Error).message);
    }
  }, [skuRef]);

  const uploadFiles = useCallback(
    async (files: FileList | File[]) => {
      const list = Array.from(files);
      if (list.length === 0) return;
      setUploading(true);
      setMessage(null);
      try {
        for (const file of list) {
          const form = new FormData();
          form.set("ref", skuRef);
          form.set("category", category);
          form.set("file", file);
          const res = await fetch("/api/product-documents", { method: "POST", body: form });
          const json = await res.json();
          if (!res.ok) throw new Error(json.error || `Échec de l'envoi de "${file.name}".`);
        }
        await reload();
      } catch (e) {
        setMessage((e as Error).message);
      } finally {
        setUploading(false);
        if (fileInputRef.current) fileInputRef.current.value = "";
      }
    },
    [skuRef, category, reload]
  );

  const handleDelete = useCallback(
    async (id: string) => {
      setDocuments((prev) => prev.filter((d) => d.id !== id));
      try {
        const res = await fetch(`/api/product-documents?id=${encodeURIComponent(id)}`, {
          method: "DELETE",
        });
        if (!res.ok) {
          const json = await res.json();
          throw new Error(json.error || "Échec de la suppression.");
        }
      } catch (e) {
        setMessage((e as Error).message);
        reload();
      }
    },
    [reload]
  );

  const grouped = DOCUMENT_CATEGORIES.map((c) => ({
    ...c,
    items: documents.filter((d) => d.category === c.value),
  }));

  return (
    <div className="docs-panel">
      <h3 className="docs-title">Documents</h3>
      <p className="docs-hint">
        Die cuts, designs cartons, technical data sheets… glissez vos fichiers, ils ne sont pas
        générés par l&apos;app, seulement classés ici par référence.
      </p>

      <div className="docs-upload-row">
        <select
          className="docs-category-select"
          value={category}
          onChange={(e) => setCategory(e.target.value as DocumentCategory)}
          disabled={uploading}
        >
          {DOCUMENT_CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>
              {c.label}
            </option>
          ))}
        </select>

        <div
          className={`docs-dropzone ${dragActive ? "active" : ""}`}
          onClick={() => fileInputRef.current?.click()}
          onDragOver={(e) => {
            e.preventDefault();
            setDragActive(true);
          }}
          onDragLeave={() => setDragActive(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDragActive(false);
            if (e.dataTransfer.files?.length) uploadFiles(e.dataTransfer.files);
          }}
        >
          {uploading ? "Envoi en cours…" : "Glissez vos fichiers ici ou cliquez pour parcourir"}
          <input
            ref={fileInputRef}
            type="file"
            accept={ACCEPT}
            multiple
            style={{ display: "none" }}
            onChange={(e) => {
              if (e.target.files?.length) uploadFiles(e.target.files);
            }}
          />
        </div>
      </div>

      {message && <div className="docs-message">{message}</div>}

      {loading ? (
        <div className="docs-empty">Chargement…</div>
      ) : (
        <div className="docs-groups">
          {grouped.map((g) => (
            <div className="docs-group" key={g.value}>
              <div className="docs-group-title">
                {g.label} <span className="docs-count">({g.items.length})</span>
              </div>
              {g.items.length === 0 ? (
                <div className="docs-empty">Aucun fichier</div>
              ) : (
                <ul className="docs-list">
                  {g.items.map((d) => (
                    <li className="docs-item" key={d.id}>
                      <a href={d.url} target="_blank" rel="noopener noreferrer" className="docs-item-name">
                        {d.fileName}
                      </a>
                      <span className="docs-item-meta">
                        {formatSize(d.fileSize)} · {formatDate(d.uploadedAt)}
                      </span>
                      <button
                        type="button"
                        className="docs-item-delete"
                        onClick={() => handleDelete(d.id)}
                        aria-label={`Supprimer ${d.fileName}`}
                      >
                        ✕
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

MBA_EOF_4

cat > src/app/api/product-documents/route.ts <<'MBA_EOF_5'
import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin, PRODUCT_DOCUMENTS_BUCKET } from "@/lib/supabaseAdmin";
import {
  DOCUMENT_CATEGORIES,
  rowToDocument,
  type DocumentCategory,
  type ProductDocumentRow,
} from "@/lib/documentTypes";

export const runtime = "nodejs";
export const maxDuration = 30;

const VALID_CATEGORIES = new Set(DOCUMENT_CATEGORIES.map((c) => c.value));

// GET /api/product-documents?ref=<sku ref>
// Lists every extra document (die cut, carton design, technical data
// sheet, etc.) attached to a given product sheet, most recent first.
export async function GET(req: NextRequest) {
  const ref = req.nextUrl.searchParams.get("ref")?.trim() ?? "";
  if (!ref) {
    return NextResponse.json({ error: "Paramètre 'ref' manquant." }, { status: 400 });
  }

  const supabase = supabaseAdmin();
  const { data, error } = await supabase
    .from("product_documents")
    .select("*")
    .eq("ref", ref)
    .order("uploaded_at", { ascending: false });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const documents = (data as ProductDocumentRow[]).map((row) => {
    const { data: pub } = supabase.storage
      .from(PRODUCT_DOCUMENTS_BUCKET)
      .getPublicUrl(row.storage_path);
    return rowToDocument(row, pub.publicUrl);
  });

  return NextResponse.json({ documents });
}

// POST /api/product-documents
// multipart/form-data with:
//   - "ref": the SKU reference the document belongs to (must already exist
//     in product_sheets)
//   - "category": one of DOCUMENT_CATEGORIES
//   - "file": the file being stored (never generated by the app — this is
//     purely a place to file away documents the user already has)
export async function POST(req: NextRequest) {
  const form = await req.formData();
  const ref = (form.get("ref") as string | null)?.trim() ?? "";
  const category = (form.get("category") as string | null)?.trim() ?? "";
  const file = form.get("file");

  if (!ref) {
    return NextResponse.json({ error: "Paramètre 'ref' manquant." }, { status: 400 });
  }
  if (!VALID_CATEGORIES.has(category as DocumentCategory)) {
    return NextResponse.json({ error: "Catégorie de document invalide." }, { status: 400 });
  }
  if (!(file instanceof File) || file.size === 0) {
    return NextResponse.json({ error: "Aucun fichier reçu." }, { status: 400 });
  }

  const supabase = supabaseAdmin();

  // Verify the SKU exists before filing a document under it.
  const { data: sheet, error: sheetError } = await supabase
    .from("product_sheets")
    .select("ref")
    .eq("ref", ref)
    .maybeSingle();
  if (sheetError) {
    return NextResponse.json({ error: sheetError.message }, { status: 500 });
  }
  if (!sheet) {
    return NextResponse.json(
      { error: `Aucune fiche produit trouvée pour la référence "${ref}".` },
      { status: 404 }
    );
  }

  const safeName = file.name.replace(/[^a-zA-Z0-9._-]+/g, "_");
  const storagePath = `${ref}/${category}/${Date.now()}-${safeName}`;
  const bytes = Buffer.from(await file.arrayBuffer());

  const { error: uploadError } = await supabase.storage
    .from(PRODUCT_DOCUMENTS_BUCKET)
    .upload(storagePath, bytes, { contentType: file.type || "application/octet-stream" });
  if (uploadError) {
    return NextResponse.json({ error: uploadError.message }, { status: 500 });
  }

  const insertRow = {
    ref,
    category,
    file_name: file.name,
    storage_path: storagePath,
    mime_type: file.type || null,
    file_size: file.size,
  };

  const { data: inserted, error: insertError } = await supabase
    .from("product_documents")
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    .insert(insertRow as any)
    .select("*")
    .single();

  if (insertError) {
    return NextResponse.json({ error: insertError.message }, { status: 500 });
  }

  const { data: pub } = supabase.storage
    .from(PRODUCT_DOCUMENTS_BUCKET)
    .getPublicUrl((inserted as ProductDocumentRow).storage_path);

  return NextResponse.json(
    { document: rowToDocument(inserted as ProductDocumentRow, pub.publicUrl) },
    { status: 201 }
  );
}

// DELETE /api/product-documents?id=<document id>
export async function DELETE(req: NextRequest) {
  const id = req.nextUrl.searchParams.get("id")?.trim() ?? "";
  if (!id) {
    return NextResponse.json({ error: "Paramètre 'id' manquant." }, { status: 400 });
  }

  const supabase = supabaseAdmin();

  const { data: existing, error: fetchError } = await supabase
    .from("product_documents")
    .select("storage_path")
    .eq("id", id)
    .maybeSingle();
  if (fetchError) {
    return NextResponse.json({ error: fetchError.message }, { status: 500 });
  }
  if (!existing) {
    return NextResponse.json({ error: "Document introuvable." }, { status: 404 });
  }

  const { error: removeError } = await supabase.storage
    .from(PRODUCT_DOCUMENTS_BUCKET)
    .remove([(existing as { storage_path: string }).storage_path]);
  if (removeError) {
    return NextResponse.json({ error: removeError.message }, { status: 500 });
  }

  const { error: deleteError } = await supabase
    .from("product_documents")
    .delete()
    .eq("id", id);
  if (deleteError) {
    return NextResponse.json({ error: deleteError.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}

MBA_EOF_5

echo "Fichiers ecrits. Verification git status..."
git add -A
git status

echo "Pret. Verifiez le status ci-dessus puis lancez :"
echo "  git commit -m \"Ajout gestion documents produit (die cuts, designs cartons, TDS)\""
echo "  git push"