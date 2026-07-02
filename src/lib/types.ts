// Core data shape for a product sheet (fiche produit).
// Field names are camelCase in the app/UI layer; the Supabase table uses snake_case
// (see supabaseRowToSheet / sheetToSupabaseRow below for the mapping).

export interface ProductSheetData {
  id?: string;
  ref: string;
  nameFr: string;
  nameEn: string;
  eanBox: string;
  eanUvc: string;
  customCode: string;

  material: string;
  capacity: string;
  height: string;
  diameter: string;
  length: string;
  gusset: string;
  width: string;
  netWeight: string;

  unitsPerUvc: string;
  uvcWeight: string;

  unitsPerBox: string;
  boxDim: string;
  boxGross: string;
  boxNet: string;
  boxVolume: string;

  unitsPerPallet: string;
  boxesPerPallet: string;
  layersPerPallet: string;
  boxesPerLayer: string;
  palletHeight: string;
  palletWeight: string;
  palletVolume: string;

  tolerance: string;
  imageUrl?: string | null;
  pdfUrl?: string | null;
  createdAt?: string;
  updatedAt?: string;
}

export const EMPTY_SHEET: ProductSheetData = {
  ref: "",
  nameFr: "",
  nameEn: "",
  eanBox: "",
  eanUvc: "",
  customCode: "",
  material: "",
  capacity: "",
  height: "",
  diameter: "",
  length: "",
  gusset: "",
  width: "",
  netWeight: "",
  unitsPerUvc: "",
  uvcWeight: "",
  unitsPerBox: "",
  boxDim: "",
  boxGross: "",
  boxNet: "",
  boxVolume: "",
  unitsPerPallet: "",
  boxesPerPallet: "",
  layersPerPallet: "",
  boxesPerLayer: "",
  palletHeight: "",
  palletWeight: "",
  palletVolume: "",
  tolerance: "",
  imageUrl: null,
  pdfUrl: null,
};

// Row shape as stored in the Supabase `product_sheets` table (snake_case).
export interface ProductSheetRow {
  id: string;
  ref: string;
  name_fr: string | null;
  name_en: string | null;
  ean_box: string | null;
  ean_uvc: string | null;
  custom_code: string | null;
  material: string | null;
  capacity: string | null;
  height: string | null;
  diameter: string | null;
  length: string | null;
  gusset: string | null;
  width: string | null;
  net_weight: string | null;
  units_per_uvc: string | null;
  uvc_weight: string | null;
  units_per_box: string | null;
  box_dim: string | null;
  box_gross: string | null;
  box_net: string | null;
  box_volume: string | null;
  units_per_pallet: string | null;
  boxes_per_pallet: string | null;
  layers_per_pallet: string | null;
  boxes_per_layer: string | null;
  pallet_height: string | null;
  pallet_weight: string | null;
  pallet_volume: string | null;
  tolerance: string | null;
  image_url: string | null;
  pdf_url: string | null;
  created_at: string;
  updated_at: string;
}

export function rowToSheet(row: ProductSheetRow): ProductSheetData {
  return {
    id: row.id,
    ref: row.ref ?? "",
    nameFr: row.name_fr ?? "",
    nameEn: row.name_en ?? "",
    eanBox: row.ean_box ?? "",
    eanUvc: row.ean_uvc ?? "",
    customCode: row.custom_code ?? "",
    material: row.material ?? "",
    capacity: row.capacity ?? "",
    height: row.height ?? "",
    diameter: row.diameter ?? "",
    length: row.length ?? "",
    gusset: row.gusset ?? "",
    width: row.width ?? "",
    netWeight: row.net_weight ?? "",
    unitsPerUvc: row.units_per_uvc ?? "",
    uvcWeight: row.uvc_weight ?? "",
    unitsPerBox: row.units_per_box ?? "",
    boxDim: row.box_dim ?? "",
    boxGross: row.box_gross ?? "",
    boxNet: row.box_net ?? "",
    boxVolume: row.box_volume ?? "",
    unitsPerPallet: row.units_per_pallet ?? "",
    boxesPerPallet: row.boxes_per_pallet ?? "",
    layersPerPallet: row.layers_per_pallet ?? "",
    boxesPerLayer: row.boxes_per_layer ?? "",
    palletHeight: row.pallet_height ?? "",
    palletWeight: row.pallet_weight ?? "",
    palletVolume: row.pallet_volume ?? "",
    tolerance: row.tolerance ?? "",
    imageUrl: row.image_url,
    pdfUrl: row.pdf_url,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function sheetToInsertRow(d: ProductSheetData) {
  return {
    ref: d.ref,
    name_fr: d.nameFr || null,
    name_en: d.nameEn || null,
    ean_box: d.eanBox || null,
    ean_uvc: d.eanUvc || null,
    custom_code: d.customCode || null,
    material: d.material || null,
    capacity: d.capacity || null,
    height: d.height || null,
    diameter: d.diameter || null,
    length: d.length || null,
    gusset: d.gusset || null,
    width: d.width || null,
    net_weight: d.netWeight || null,
    units_per_uvc: d.unitsPerUvc || null,
    uvc_weight: d.uvcWeight || null,
    units_per_box: d.unitsPerBox || null,
    box_dim: d.boxDim || null,
    box_gross: d.boxGross || null,
    box_net: d.boxNet || null,
    box_volume: d.boxVolume || null,
    units_per_pallet: d.unitsPerPallet || null,
    boxes_per_pallet: d.boxesPerPallet || null,
    layers_per_pallet: d.layersPerPallet || null,
    boxes_per_layer: d.boxesPerLayer || null,
    pallet_height: d.palletHeight || null,
    pallet_weight: d.palletWeight || null,
    pallet_volume: d.palletVolume || null,
    tolerance: d.tolerance || null,
    image_url: d.imageUrl || null,
    pdf_url: d.pdfUrl || null,
  };
}

export function materialFamily(material: string | null | undefined): string {
  const mat = (material || "").toUpperCase();
  if (mat.includes("CORRUGAT")) return "Carton cannelé";
  if (mat.includes("PE") || mat.includes("PLASTIC")) return "Papier + PE";
  if (mat.includes("PAPER") || mat.includes("PAPIER")) return "Papier";
  return "Autre";
}
