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
