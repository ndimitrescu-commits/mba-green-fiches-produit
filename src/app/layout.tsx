import type { Metadata } from "next";
import { Space_Grotesk, Work_Sans, Archivo_Black } from "next/font/google";
import "./globals.css";
import "./sheet.css";
import AppHeader from "@/components/AppHeader";

const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  weight: ["500", "600", "700"],
  subsets: ["latin"],
});

// Aligné sur la police "corps de texte" des autres outils MBA Green
// (GEODIS, GLS, demand-planning, Rapports) — remplace Inter (demande
// Nicolas 10/09/2026 : « même traitement » que ce qui vient d'être fait
// pour ces outils). Garde le nom de variable --font-sans historique
// (var(--font-inter) n'était référencé qu'à un seul endroit dans
// globals.css, mis à jour en même temps).
const workSans = Work_Sans({
  variable: "--font-sans",
  weight: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

// Logo du header unifié — même police que les 4 autres outils.
const archivoBlack = Archivo_Black({
  variable: "--font-archivo-black",
  weight: "400",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "MBA Green — Fiches Produit",
  description: "Répertoire et générateur de fiches produit MBA Green",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="fr"
      className={`${spaceGrotesk.variable} ${workSans.variable} ${archivoBlack.variable}`}
    >
      <body>
        <AppHeader />
        <main>{children}</main>
      </body>
    </html>
  );
}
