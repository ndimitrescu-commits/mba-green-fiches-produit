#!/bin/bash
set -e
echo "Applying: edit-fiche flow (Modifier cette fiche) + PDF-overwrite safety fix..."

mkdir -p src/app/api/product-sheets
cat > src/app/api/product-sheets/route.ts <<'FILEEOF'
import { NextRequest, NextResponse } from "next/server";
import {
  supabaseAdmin,
  PRODUCT_IMAGES_BUCKET,
  PRODUCT_PDFS_BUCKET,
} from "@/lib/supabaseAdmin";
import {
  rowToSheet,
  sheetToInsertRow,
  type ProductSheetData,
  type ProductSheetRow,
} from "@/lib/types";
import { generateSheetPdf } from "@/lib/pdf";

export const runtime = "nodejs";
export const maxDuration = 60;

// GET /api/product-sheets?q=<search text>
// Simple substring search across ref / names / EANs / material, mirroring
// the prototype's client-side filter behaviour exactly.
export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q")?.trim() ?? "";
  const supabase = supabaseAdmin();

  let query = supabase
    .from("product_sheets")
    .select("*")
    .order("created_at", { ascending: false });

  if (q) {
    const like = `%${q}%`;
    query = query.or(
      [
        `ref.ilike.${like}`,
        `name_fr.ilike.${like}`,
        `name_en.ilike.${like}`,
        `ean_box.ilike.${like}`,
        `ean_uvc.ilike.${like}`,
        `material.ilike.${like}`,
      ].join(",")
    );
  }

  const { data, error } = await query;
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const sheets = (data as ProductSheetRow[]).map(rowToSheet);
  return NextResponse.json({ sheets });
}

// POST /api/product-sheets
// multipart/form-data with:
//   - "data": JSON string of ProductSheetData fields (ref required)
//   - "image": optional File, the product visual
// Creates (or updates, if the ref already exists) the record, uploads the
// image if provided, generates the PDF server-side from the same template
// used in the live preview, uploads the PDF, and returns the saved sheet.
export async function POST(req: NextRequest) {
  const form = await req.formData();
  const rawData = form.get("data");
  if (typeof rawData !== "string") {
    return NextResponse.json({ error: "Missing 'data' field." }, { status: 400 });
  }

  let parsed: Partial<ProductSheetData>;
  try {
    parsed = JSON.parse(rawData);
  } catch {
    return NextResponse.json({ error: "Invalid JSON in 'data' field." }, { status: 400 });
  }

  const ref = (parsed.ref || "").trim();
  if (!ref) {
    return NextResponse.json({ error: "Le champ référence est obligatoire." }, { status: 400 });
  }

  const supabase = supabaseAdmin();
  let imageUrl: string | null = parsed.imageUrl ?? null;

  const imageFile = form.get("image");
  if (imageFile instanceof File && imageFile.size > 0) {
    const ext = imageFile.name.split(".").pop() || "png";
    const path = `${ref}/${Date.now()}.${ext}`;
    const bytes = Buffer.from(await imageFile.arrayBuffer());
    const { error: uploadError } = await supabase.storage
      .from(PRODUCT_IMAGES_BUCKET)
      .upload(path, bytes, { contentType: imageFile.type, upsert: true });
    if (uploadError) {
      return NextResponse.json({ error: uploadError.message }, { status: 500 });
    }
    const { data: pub } = supabase.storage.from(PRODUCT_IMAGES_BUCKET).getPublicUrl(path);
    imageUrl = pub.publicUrl;
  }

  const sheetData: ProductSheetData = {
    ...(parsed as ProductSheetData),
    ref,
    imageUrl,
  };

  // Some sheets (bulk-imported from the client's Drive) deliberately link to
  // an original datasheet the client's team made themselves, rather than one
  // we generated — that's stored as-is in pdf_url. Editing such a sheet (e.g.
  // via "Modifier cette fiche") must never silently clobber that original
  // with a freshly generated PDF. Only (re)generate when there's no pdf_url
  // yet, or the existing one already points at our own storage bucket.
  const { data: existingRow } = await supabase
    .from("product_sheets")
    .select("pdf_url")
    .eq("ref", ref)
    .maybeSingle();
  const existingPdfUrl = (existingRow as { pdf_url: string | null } | null)?.pdf_url ?? null;
  const isOwnGeneratedPdf = (url: string | null) =>
    !!url && url.includes(`/storage/v1/object/public/${PRODUCT_PDFS_BUCKET}/`);

  let pdfUrl: string | null = existingPdfUrl;
  if (!existingPdfUrl || isOwnGeneratedPdf(existingPdfUrl)) {
    // Generate the PDF from the exact same template as the on-screen preview.
    try {
      const pdfBuffer = await generateSheetPdf(sheetData);
      const pdfPath = `${ref}.pdf`;
      const { error: pdfUploadError } = await supabase.storage
        .from(PRODUCT_PDFS_BUCKET)
        .upload(pdfPath, pdfBuffer, { contentType: "application/pdf", upsert: true });
      if (pdfUploadError) {
        return NextResponse.json({ error: pdfUploadError.message }, { status: 500 });
      }
      const { data: pub } = supabase.storage.from(PRODUCT_PDFS_BUCKET).getPublicUrl(pdfPath);
      pdfUrl = pub.publicUrl;
    } catch (e) {
      return NextResponse.json(
        { error: `Échec de la génération du PDF: ${(e as Error).message}` },
        { status: 500 }
      );
    }
  }

  const insertRow = { ...sheetToInsertRow(sheetData), image_url: imageUrl, pdf_url: pdfUrl };

  const { data: saved, error: dbError } = await supabase
    .from("product_sheets")
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    .upsert(insertRow as any, { onConflict: "ref" })
    .select("*")
    .single();

  if (dbError) {
    return NextResponse.json({ error: dbError.message }, { status: 500 });
  }

  return NextResponse.json({ sheet: rowToSheet(saved as ProductSheetRow) }, { status: 201 });
}
FILEEOF

mkdir -p src/app
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
input:disabled, select:disabled{background:var(--line); color:var(--ink-soft); cursor:not-allowed;}
.field-hint{font-size:11px; color:var(--ink-soft); margin-top:3px;}
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

mkdir -p src/app/nouvelle-fiche
cat > src/app/nouvelle-fiche/page.tsx <<'FILEEOF'
import { supabaseAdmin } from "@/lib/supabaseAdmin";
import { rowToSheet, type ProductSheetRow } from "@/lib/types";
import NouvelleFicheClient from "@/components/NouvelleFicheClient";

export const dynamic = "force-dynamic";

// Reused for both "Nouvelle fiche" (no ?ref=) and "Modifier cette fiche"
// (?ref=<existing ref>, prefills the form with that sheet's current data —
// see RepertoireClient.tsx's "Modifier cette fiche" link).
export default async function NouvelleFichePage({
  searchParams,
}: {
  searchParams: Promise<{ ref?: string }>;
}) {
  const { ref } = await searchParams;
  if (!ref) {
    return <NouvelleFicheClient />;
  }

  const supabase = supabaseAdmin();
  const { data } = await supabase
    .from("product_sheets")
    .select("*")
    .eq("ref", ref)
    .maybeSingle();

  const initialData = data ? rowToSheet(data as ProductSheetRow) : undefined;
  return <NouvelleFicheClient initialData={initialData} />;
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
  disabled,
  hint,
}: {
  label: string;
  field: Field;
  placeholder?: string;
  value: string;
  onChange: (field: Field, value: string) => void;
  disabled?: boolean;
  hint?: string;
}) {
  return (
    <div>
      <label>{label}</label>
      <input
        type="text"
        placeholder={placeholder}
        value={value}
        disabled={disabled}
        onChange={(e) => onChange(field, e.target.value)}
      />
      {hint ? <div className="field-hint">{hint}</div> : null}
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

export default function NouvelleFicheClient({
  initialData,
}: {
  initialData?: ProductSheetData;
}) {
  const router = useRouter();
  const isEditing = !!initialData;
  const [data, setData] = useState<ProductSheetData>(
    initialData ? { ...initialData } : { ...EMPTY_SHEET }
  );
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(initialData?.imageUrl ?? null);
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
      showToast(isEditing ? `Fiche « ${data.ref} » mise à jour.` : `Fiche « ${data.ref} » ajoutée au répertoire.`);
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
          <h1>{isEditing ? `Modifier la fiche — ${data.ref}` : "Nouvelle fiche produit"}</h1>
          <p>
            {isEditing
              ? "Modifie les champs souhaités — l'aperçu à droite se met à jour en direct."
              : "Renseignez les champs — l'aperçu à droite se met à jour en direct."}
          </p>
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
                <Text
                  label="Référence MBA Green"
                  field="ref"
                  placeholder="BOXFRIES01ORG"
                  value={data.ref}
                  onChange={set}
                  disabled={isEditing}
                  hint={isEditing ? "Verrouillée en modification (change la fiche, pas la référence)." : undefined}
                />
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
              {submitting ? "Enregistrement en cours…" : isEditing ? "Mettre à jour la fiche" : "Générer la fiche PDF"}
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
              {submitting ? "Enregistrement…" : isEditing ? "Mettre à jour la fiche" : "Enregistrer & ajouter au répertoire"}
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
              <a className="btn" href={`/nouvelle-fiche?ref=${encodeURIComponent(modalSheet.ref)}`}>
                Modifier cette fiche
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
echo "Done. Review the diff, then: git commit -m \"Add edit-fiche flow, protect external pdf_url from being overwritten\" && git push"
