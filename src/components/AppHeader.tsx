"use client";

/**
 * Barre de navigation partagée — remplace l'ancien bandeau simple (logo
 * image + 2 onglets) par le menu unifié des autres outils MBA Green
 * (dashboard, GEODIS, GLS, demand-planning, Rapports) : logo texte
 * cliquable vers l'intranet, menu principal avec sous-menus déroulants
 * (Logistique / Approvisionnement / Commandes / Autres), et une bande
 * secondaire propre à cet outil avec ses 2 pages (demande Nicolas
 * 10/09/2026 : « même traitement » que GLS/Geodis/Demand planning/
 * Rapports). "Autres" est actif ici puisque Fiches produit en fait partie.
 */
import Link from "next/link";
import { usePathname } from "next/navigation";
import { NavDropdown } from "./NavDropdown";

const MENU_GROUPS = [
  {
    label: "Logistique",
    items: [
      { label: "GEODIS", href: "https://suivi-livraisons-geodis.vercel.app/" },
      { label: "GLS", href: "https://gls-suivi.vercel.app/" },
    ],
  },
  {
    label: "Approvisionnement",
    items: [
      { label: "Demand planning", href: "https://mba-green-demand-planning.vercel.app/conso" },
      { label: "Approvisionnement", href: "https://mba-green-procurement.vercel.app/rfq" },
    ],
  },
  {
    label: "Commandes",
    items: [
      { label: "CSV Generator", href: "https://mbagreen-app-production.up.railway.app/login" },
      { label: "Portail B2B", href: "https://mba-green-portal.vercel.app/" },
    ],
  },
  {
    label: "Autres",
    items: [
      { label: "Rapports mensuels", href: "https://mba-green-rapports.vercel.app/" },
      { label: "Datasheet Database", href: "https://mba-green-fiches-produit.vercel.app/repertoire" },
    ],
  },
];

const NAV_ITEMS: { href: string; label: string }[] = [
  { href: "/repertoire", label: "Répertoire" },
  { href: "/nouvelle-fiche", label: "Nouvelle fiche" },
];

export default function AppHeader() {
  const pathname = usePathname();

  return (
    <header className="mba-header">
      <div className="mba-header-row">
        <div className="mba-header-left">
          <a href="https://intranet.mbagreen.net" className="mba-logo">
            MBA<span className="mba-logo-accent">GREEN™</span>
          </a>
          <nav className="mba-nav">
            <a href="https://intranet.mbagreen.net" className="mba-nav-link">
              Vue d&apos;ensemble
            </a>
            {MENU_GROUPS.map((group) => (
              <NavDropdown key={group.label} label={group.label} items={group.items} active={group.label === "Autres"} />
            ))}
          </nav>
        </div>
      </div>

      <div className="mba-secondary">
        <div className="mba-secondary-inner">
          <span className="mba-secondary-label">FICHES PRODUIT</span>
          <nav className="mba-secondary-nav">
            {NAV_ITEMS.map((item) => {
              const isActive =
                item.href === "/repertoire"
                  ? pathname === "/" || pathname?.startsWith("/repertoire")
                  : pathname?.startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`mba-secondary-link${isActive ? " active" : ""}`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>
    </header>
  );
}
