"use client";

/**
 * Sous-menu du header — repris à l'identique des autres outils MBA Green
 * (GEODIS, GLS, demand-planning, Rapports) pour un menu de navigation
 * unifié (demande Nicolas 10/09/2026 : « même traitement » que ce qui
 * vient d'être fait pour ces outils). Ce projet utilise des classes CSS
 * (globals.css) plutôt que des styles inline, contrairement à Rapports —
 * même comportement (clic pour ouvrir, ferme au clic extérieur / Échap /
 * sélection d'un lien) via className plutôt que style={{}}.
 *
 * Toujours des liens externes (autres outils déployés séparément) :
 * ouverture en nouvel onglet pour garder l'outil courant.
 *
 * `active` force le style "sélectionné" même fermé — utilisé ici pour
 * "Autres", puisque cet outil (Fiches produit) en fait partie.
 */
import { useEffect, useRef, useState } from "react";

export interface NavDropdownItem {
  label: string;
  href: string;
}

export function NavDropdown({
  label,
  items,
  active = false,
}: {
  label: string;
  items: NavDropdownItem[];
  active?: boolean;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onPointerDown(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }
    document.addEventListener("mousedown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("mousedown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, []);

  const highlighted = open || active;

  return (
    <div className="mba-dropdown" ref={ref}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className={`mba-dropdown-btn${highlighted ? " highlighted" : ""}`}
      >
        {label}
        <svg
          width="10"
          height="6"
          viewBox="0 0 10 6"
          fill="none"
          style={{ transform: open ? "rotate(180deg)" : undefined, transition: "transform 0.15s" }}
        >
          <path d="M1 1L5 5L9 1" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </button>
      {open && (
        <div className="mba-dropdown-panel">
          {items.map((item) => (
            <a
              key={item.href}
              href={item.href}
              target="_blank"
              rel="noopener noreferrer"
              onClick={() => setOpen(false)}
              className="mba-dropdown-item"
            >
              {item.label}
              <span className="arrow">↗</span>
            </a>
          ))}
        </div>
      )}
    </div>
  );
}
