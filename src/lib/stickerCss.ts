// Inline CSS for the printable carton sticker (see stickerHtml.ts / stickerPdf.ts).
// Kept as a standalone string so the PDF route can embed it in a plain HTML
// document — same pattern as sheetCss.ts for the main datasheet.
export const STICKER_CSS = `
*{box-sizing:border-box;}
html,body{margin:0;padding:0;}
body{
  padding:20px; background:#fff; font-family:'Inter',sans-serif; color:#111;
}
.sticker{
  width:640px; height:380px;
  border:4px solid #111; border-radius:28px; overflow:hidden;
  display:flex; flex-direction:column; background:#fff;
}
.sticker-main{ display:flex; flex:1; }
.sticker-icon{
  width:150px; flex-shrink:0;
  border-right:2px solid #111; border-bottom:2px solid #111;
  display:flex; align-items:center; justify-content:center;
}
.sticker-info{ flex:1; display:flex; flex-direction:column; min-width:0; }
.sticker-row{
  flex:1; border-bottom:2px solid #111; display:flex; align-items:center; padding:0 22px; gap:8px; min-width:0;
}
.sticker-row-split{ padding:0; }
.sticker-cell{ flex:1; padding:0 22px; display:flex; align-items:center; gap:8px; min-width:0; }
.sticker-cell:first-child{ border-right:2px solid #111; }
.k{ font-size:16px; color:#111; white-space:nowrap; }
.v{ font-size:22px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.sticker-footer{ height:110px; display:flex; align-items:stretch; }
.sticker-logo{
  width:150px; flex-shrink:0; border-right:2px solid #111;
  display:flex; align-items:center; justify-content:center;
}
.sticker-logo-mark{
  background:#111; color:#fff; font-weight:700; font-size:14px; text-align:center; line-height:1.15;
  padding:12px 16px; clip-path: polygon(15% 0, 85% 0, 100% 100%, 0% 100%);
}
.sticker-logo-mark span{ display:block; font-size:14px; }
.sticker-spacer{ flex:1; }
.sticker-barcode{ display:flex; flex-direction:column; align-items:center; justify-content:center; padding-right:26px; }
.sticker-barcode-digits{ font-size:15px; letter-spacing:2px; margin-top:2px; }
`;
