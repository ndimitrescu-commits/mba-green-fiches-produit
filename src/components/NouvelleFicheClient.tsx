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
}: {
  label: string;
  field: Field;
  placeholder?: string;
  value: string;
  onChange: (field: Field, value: string) => void;
}) {
  return (
    <div>
      <label>{label}</label>
      <input
        type="text"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(field, e.target.value)}
      />
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

export default function NouvelleFicheClient() {
  const router = useRouter();
  const [data, setData] = useState<ProductSheetData>({ ...EMPTY_SHEET });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
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
      showToast(`Fiche « ${data.ref} » ajoutée au répertoire.`);
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
          <h1>Nouvelle fiche produit</h1>
          <p>Renseignez les champs — l&apos;aperçu à droite se met à jour en direct.</p>
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
                <Text label="Référence MBA Green" field="ref" placeholder="BOXFRIES01ORG" value={data.ref} onChange={set} />
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
              {submitting ? "Génération en cours…" : "Générer la fiche PDF"}
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
              {submitting ? "Enregistrement…" : "Enregistrer & ajouter au répertoire"}
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
