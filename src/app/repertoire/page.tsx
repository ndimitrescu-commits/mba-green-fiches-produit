import { supabaseAdmin } from "@/lib/supabaseAdmin";
import { rowToSheet, type ProductSheetRow } from "@/lib/types";
import RepertoireClient from "@/components/RepertoireClient";

export const dynamic = "force-dynamic";

export default async function RepertoirePage() {
  const supabase = supabaseAdmin();
  const { data, error } = await supabase
    .from("product_sheets")
    .select("*")
    .order("created_at", { ascending: false });

  const sheets = error ? [] : (data as ProductSheetRow[]).map(rowToSheet);

  return <RepertoireClient initialSheets={sheets} loadError={error?.message ?? null} />;
}
