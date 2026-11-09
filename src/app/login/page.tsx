"use client";

import { Suspense, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ password }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error ?? "Erreur de connexion");
      }
      router.push(searchParams.get("next") || "/repertoire");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erreur inconnue");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-paper px-6">
      <div className="w-full max-w-[360px] border border-hairline bg-white p-8">
        <div className="text-xl" style={{ fontFamily: "var(--font-archivo-black), sans-serif" }}>
          MBA<span className="text-[#c6f24e]">GREEN™</span>
        </div>
        <h1 className="mt-3 font-display text-[22px] font-semibold text-ink">Fiches produit</h1>
        <p className="mt-1 mb-6 text-[13px] text-ink-soft">
          Outil interne — accès équipe MBA Green uniquement.
        </p>
        <form onSubmit={handleSubmit}>
          <label className="mb-1.5 block text-[11px] font-semibold uppercase tracking-wide text-ink-faint">
            Mot de passe
          </label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoFocus
            required
            className="mb-4 h-10 w-full border border-hairline bg-white px-3 text-[13px] text-ink focus:border-ink focus:outline-none focus:ring-[3px] focus:ring-ink/10"
          />
          {error && <p className="mb-4 text-[13px] text-accent-orange">{error}</p>}
          <button
            type="submit"
            disabled={loading}
            className="inline-flex h-10 w-full items-center justify-center bg-ink text-[13px] font-medium text-cream transition-colors hover:bg-[#2a2a27] disabled:cursor-not-allowed disabled:opacity-50"
          >
            {loading ? "Connexion…" : "Entrer"}
          </button>
        </form>
      </div>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={null}>
      <LoginForm />
    </Suspense>
  );
}
