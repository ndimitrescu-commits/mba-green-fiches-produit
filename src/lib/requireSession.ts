import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { SESSION_COOKIE, isValidSessionToken } from "@/lib/auth";

// Vérification de session DANS la route (9/11/2026, correctif de sécurité) : défense en profondeur, en plus de src/proxy.ts.
// Fiches produit : l’outil n’avait aucune connexion ; mot de passe FICHES_PASSWORD (variable Vercel, posée par Nicolas).
// Le garde général était posé à la racine (proxy.ts) alors que l'application vit dans src/ : Next.js ne l'exécutait pas, et les
// routes d'action répondaient sans connexion. Retourne null si la session est valide, sinon une réponse 401.
export async function requireSession(): Promise<NextResponse | null> {
  const token = (await cookies()).get(SESSION_COOKIE)?.value;
  return isValidSessionToken(token) ? null : NextResponse.json({ error: "Non autorisé" }, { status: 401 });
}
