"use client";

import { useMemo, useState } from "react";
import { materialFamily, type ProductSheetData } from "@/lib/types";
import ProductSheetView from "@/components/ProductSheetView";
import ProductDocuments from "@/components/ProductDocuments";

export default function RepertoireClient({
  initialSheets,
  loadError,
}: {
  initialSheets: ProductSheetData[];
  loadError: string | null;
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
    return sheets.filter((s) => {
      const matchesChip = activeChip === "Toutes" || materialFamily(s.material) === activeChip;
      if (!matchesChip) return false;
      if (!q) return true;
      const hay = [s.ref, s.nameFr, s.nameEn, s.eanBox, s.eanUvc, s.material].join(" ").toLowerCase();
      return hay.includes(q);
    });
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

      <div className="grid">
        {filtered.length === 0 ? (
          <div className="empty">
            <b>Aucun résultat</b>
            Essayez une autre référence, un autre EAN ou une autre matière.
          </div>
        ) : (
          filtered.map((s) => (
            <div className="card" key={s.id ?? s.ref} onClick={() => setModalSheet(s)}>
              <div className="card-head">
                <div className="dot" />
                <div className="ref">{s.ref}</div>
              </div>
              <div className="card-body">
                <div className="card-title">{s.nameFr}</div>
                <div className="card-meta">
                  <span>
                    EAN carton — <b>{s.eanBox || "—"}</b>
                  </span>
                  <span>
                    Dimensions carton — <b>{s.boxDim || "—"}</b>
                  </span>
                </div>
              </div>
              <div className="card-foot">
                <div className="material">{s.material}</div>
                <div className="arrow">→</div>
              </div>
            </div>
          ))
        )}
      </div>

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
              <ScaledSheet data={modalSheet} />
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

