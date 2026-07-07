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
