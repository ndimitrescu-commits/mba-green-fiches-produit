"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export default function AppHeader() {
  const pathname = usePathname();
  const isNew = pathname?.startsWith("/nouvelle-fiche");

  return (
    <header className="appbar">
      <div className="appbar-inner">
        <div className="brand">
                              <img src="/logo.png" alt="MBA Green" className="brand-logo" />
          <div className="brand-sub">Fiches produit</div>
        </div>
        <nav className="tabs">
          <Link href="/repertoire" className={!isNew ? "active" : ""}>
            Répertoire
          </Link>
          <Link href="/nouvelle-fiche" className={isNew ? "active" : ""}>
            Nouvelle fiche
          </Link>
        </nav>
      </div>
    </header>
  );
}
