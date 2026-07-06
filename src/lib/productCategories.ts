// Fixed list of product categories used to (a) let each SKU be tagged with
// a product type in the "Nouvelle fiche" form, and (b) pick the matching
// pictogram shown on the generated carton sticker (see stickerHtml.ts).

export type ProductCategory =
  | "bag"
  | "bottle"
  | "bowl"
  | "box"
  | "cup"
  | "cutlery"
  | "lid"
  | "napkin"
  | "paper"
  | "pot"
  | "straw"
  | "tray"
  | "other";

export const PRODUCT_CATEGORIES: { value: ProductCategory; label: string }[] = [
  { value: "bag", label: "Sac / pochette" },
  { value: "bottle", label: "Bouteille" },
  { value: "bowl", label: "Bol / bowl" },
  { value: "box", label: "Boîte / carton" },
  { value: "cup", label: "Gobelet" },
  { value: "cutlery", label: "Couverts" },
  { value: "lid", label: "Couvercle" },
  { value: "napkin", label: "Serviette" },
  { value: "paper", label: "Papier / sachet / film" },
  { value: "pot", label: "Pot / ramequin" },
  { value: "straw", label: "Paille / pique / touillette" },
  { value: "tray", label: "Plateau" },
  { value: "other", label: "Autre" },
];

// Simple flat-black pictograms, one per category, 64x64 viewBox. Kept as
// raw path/shape markup (no <svg> wrapper) so the same strings can be
// embedded both in server-rendered PDF HTML (stickerHtml.ts) and, if ever
// needed, in a React component.
const ICON_SHAPES: Record<ProductCategory, string> = {
  bag: `<rect x="16" y="12" width="32" height="10"/><polygon points="14,24 50,24 45,56 19,56"/>`,
  bottle: `<rect x="27" y="6" width="10" height="12" rx="2"/><rect x="20" y="18" width="24" height="38" rx="6"/>`,
  bowl: `<ellipse cx="32" cy="20" rx="22" ry="6"/><path d="M10 22 Q10 48 32 48 Q54 48 54 22 Z"/>`,
  box: `<polygon points="12,20 32,8 52,20"/><rect x="12" y="20" width="40" height="32"/><rect x="30" y="20" width="4" height="32" fill="#fff"/>`,
  cup: `<ellipse cx="32" cy="12" rx="14" ry="3"/><path d="M18 12h28l-5 42H23z"/>`,
  cutlery: `<rect x="22" y="6" width="4" height="26"/><rect x="30" y="6" width="4" height="26"/><rect x="38" y="6" width="4" height="26"/><rect x="20" y="28" width="24" height="6"/><rect x="29" y="30" width="6" height="28"/>`,
  lid: `<path d="M10 42 Q10 16 32 16 Q54 16 54 42 Z"/><rect x="28" y="10" width="8" height="8" rx="2"/>`,
  napkin: `<polygon points="14,16 40,14 42,20 38,30 42,42 36,50 40,58 16,56 18,44 14,36 18,26"/>`,
  paper: `<path d="M14 8h26l10 10v38H14z"/><path d="M40 8v10h10z" fill="#fff"/>`,
  pot: `<rect x="14" y="20" width="36" height="6" rx="2"/><path d="M16 26h32l-3 24a5 5 0 0 1-5 5H24a5 5 0 0 1-5-5z"/>`,
  straw: `<rect x="29" y="4" width="6" height="54" transform="rotate(18 32 32)"/>`,
  tray: `<path fill-rule="evenodd" d="M6 30a26 10 0 1 0 52 0a26 10 0 1 0 -52 0zM16 30a16 6 0 1 1 32 0a16 6 0 1 1 -32 0z"/>`,
  other: `<rect x="14" y="14" width="36" height="36" rx="8" fill="none" stroke="#111" stroke-width="4"/>`,
};

export function categoryIconSvg(category: string | null | undefined, size = 56): string {
  const key = (PRODUCT_CATEGORIES.some((c) => c.value === category) ? category : "other") as ProductCategory;
  return `<svg viewBox="0 0 64 64" width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg" fill="#111">${ICON_SHAPES[key]}</svg>`;
}

export function categoryLabel(category: string | null | undefined): string {
  return PRODUCT_CATEGORIES.find((c) => c.value === category)?.label ?? "Autre";
}
