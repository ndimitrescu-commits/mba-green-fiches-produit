import crypto from "crypto";

export const SESSION_COOKIE = "fiches_session";

function getSecret(): string {
  const secret = process.env.FICHES_PASSWORD;
  if (!secret) throw new Error("FICHES_PASSWORD non configuré");
  return secret;
}

export function computeSessionToken(): string {
  return crypto.createHmac("sha256", getSecret()).update("mba-green-fiches-produit").digest("hex");
}

export function checkPassword(input: string): boolean {
  const secret = getSecret();
  const a = Buffer.from(input);
  const b = Buffer.from(secret);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

export function isValidSessionToken(token: string | undefined): boolean {
  if (!token) return false;
  try {
    const expected = computeSessionToken();
    const a = Buffer.from(token);
    const b = Buffer.from(expected);
    if (a.length !== b.length) return false;
    return crypto.timingSafeEqual(a, b);
  } catch {
    return false;
  }
}
