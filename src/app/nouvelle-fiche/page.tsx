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
