// Standalone smoke test for PDF generation, run with:
//   npx tsx scripts/smoke-test-pdf.ts
// Not part of the app bundle — just a local sanity check that Puppeteer +
// @sparticuz/chromium can actually launch and render a sheet to PDF.
import { generateSheetPdf } from "../src/lib/pdf";
import { EMPTY_SHEET } from "../src/lib/types";
import fs from "node:fs";

async function main() {
  const data = {
    ...EMPTY_SHEET,
    ref: "TESTSKU01",
    nameFr: "Boîte test",
    nameEn: "Test box",
    eanBox: "1234567890123",
    material: "PAPER 250 GSM",
    unitsPerBox: "600",
    tolerance: "10 %",
  };
  const pdf = await generateSheetPdf(data);
  fs.writeFileSync("/tmp/smoke-test.pdf", pdf);
  console.log("PDF written, bytes:", pdf.length);
}

main().catch((e) => {
  console.error("SMOKE TEST FAILED:", e);
  process.exit(1);
});
