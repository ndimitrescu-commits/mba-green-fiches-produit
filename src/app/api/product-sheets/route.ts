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
