import type { ProductSheetData } from "@/lib/types";

function esc(v: string | null | undefined): string {
  return v === undefined || v === null || v === "" ? "—" : v;
}

/**
 * Plain-string HTML builder for the product sheet, used only for
 * server-side PDF generation (see src/lib/pdf.ts).
 *
 * Next.js App Router route handlers are not allowed to import
 * `react-dom/server` (it collides with the framework's own RSC renderer),
 * so we can't call ReactDOMServer.renderToStaticMarkup on <ProductSheetView>
 * from a route handler. Instead this function mirrors the exact markup of
 * src/components/ProductSheetView.tsx as a template string — the same
 * approach the original validated prototype used. Any layout change to
 * ProductSheetView.tsx must be mirrored here (and in sheetCss.ts / sheet.css)
 * to keep the on-screen preview and the generated PDF identical.
 */
export function buildSheetHtml(d: ProductSheetData): string {
  const img = d.imageUrl
    ? `<img src="${d.imageUrl}" alt="${esc(d.ref)}">`
    : `<div class="ph">Visuel produit<br>à insérer</div>`;

  return `
    <div class="sheet-header">
      <div class="sheet-brand"><div class="chip"></div><div class="name">MBA Green<sup>™</sup></div></div>
      <div class="sheet-titles">
        <div class="fr">${esc(d.nameFr)}</div>
        <div class="en">${esc(d.nameEn)}</div>
      </div>
    </div>
    <div class="sheet-body">
      <div class="sheet-left">
        <div class="sheet-imgbox">${img}</div>
        <div class="sheet-navlabel"><div class="fr">Caractéristiques<br>produit</div><div class="en">Product specifications</div></div>
        <div class="sheet-navlabel"><div class="fr">Conditionnement</div><div class="en">Packaging</div></div>
        <div class="sheet-navlabel"><div class="fr">Caractéristiques<br>conditionnement</div><div class="en">Packaging specifications</div></div>
      </div>
      <div class="sheet-right">
        <div class="idtable">
          <div class="idrow"><div class="k">Référence MBA Green</div><div class="v">${esc(d.ref)}</div></div>
          <div class="idrow"><div class="k">EAN carton / Box gencode</div><div class="v">${esc(d.eanBox)}</div></div>
          <div class="idrow"><div class="k">EAN UVC / Bag gencode</div><div class="v">${esc(d.eanUvc)}</div></div>
          <div class="idrow"><div class="k">Nomenclature douanière / Custom code</div><div class="v">${esc(d.customCode)}</div></div>
        </div>

        <div class="specblock">
          <div class="specblock-title">Produit / Product</div>
          <div class="specrow"><div class="k">Matière / Material</div><div class="v">${esc(d.material)}</div></div>
          <div class="specrow"><div class="k">Capacité / Capacity</div><div class="v">${esc(d.capacity)}</div></div>
          <div class="specrow"><div class="k">Hauteur / Height</div><div class="v">${esc(d.height)}</div></div>
          <div class="specrow"><div class="k">Diamètre / Diameter</div><div class="v">${esc(d.diameter)}</div></div>
          <div class="specrow"><div class="k">Longueur / Length</div><div class="v">${esc(d.length)}</div></div>
          <div class="specrow"><div class="k">Gusset</div><div class="v">${esc(d.gusset)}</div></div>
          <div class="specrow"><div class="k">Largeur / Width</div><div class="v">${esc(d.width)}</div></div>
          <div class="specrow"><div class="k">Poids net / Net weight</div><div class="v">${esc(d.netWeight)}</div></div>
        </div>

        <div class="specblock">
          <div class="specblock-title">UVC / Sales unit</div>
          <div class="specrow"><div class="k">Pièces par UVC</div><div class="v">${esc(d.unitsPerUvc)}</div></div>
          <div class="specrow"><div class="k">Poids net UVC</div><div class="v">${esc(d.uvcWeight)}</div></div>
        </div>

        <div class="specblock">
          <div class="specblock-title">Carton / Box</div>
          <div class="specrow"><div class="k">Pièces par carton</div><div class="v">${esc(d.unitsPerBox)}</div></div>
          <div class="specrow"><div class="k">Dimension carton</div><div class="v">${esc(d.boxDim)}</div></div>
          <div class="specrow"><div class="k">Poids brut carton</div><div class="v">${esc(d.boxGross)}</div></div>
          <div class="specrow"><div class="k">Poids net carton</div><div class="v">${esc(d.boxNet)}</div></div>
          <div class="specrow"><div class="k">Volume carton</div><div class="v">${esc(d.boxVolume)}</div></div>
        </div>

        <div class="specblock">
          <div class="specblock-title">Palette / Pallet</div>
          <div class="specrow"><div class="k">Pièces par palette</div><div class="v">${esc(d.unitsPerPallet)}</div></div>
          <div class="specrow"><div class="k">Cartons par palette</div><div class="v">${esc(d.boxesPerPallet)}</div></div>
          <div class="specrow"><div class="k">Couches par palette</div><div class="v">${esc(d.layersPerPallet)}</div></div>
          <div class="specrow"><div class="k">Cartons par couche</div><div class="v">${esc(d.boxesPerLayer)}</div></div>
          <div class="specrow"><div class="k">Hauteur palette</div><div class="v">${esc(d.palletHeight)}</div></div>
          <div class="specrow"><div class="k">Poids palette</div><div class="v">${esc(d.palletWeight)}</div></div>
          <div class="specrow"><div class="k">Volume palette</div><div class="v">${esc(d.palletVolume)}</div></div>
        </div>

        <div class="tolerance">Tolérance / Tolerance : ${esc(d.tolerance)}</div>
      </div>
    </div>
    <div class="sheet-footer">
      <div class="ref">${esc(d.ref)}</div>
      <div class="url">MBAGREEN.NET</div>
    </div>
  `;
}
