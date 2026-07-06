// Inline CSS for the printable carton sticker (see stickerHtml.ts / stickerPdf.ts).
// Kept as a standalone string so the PDF route can embed it in a plain HTML
// document — same pattern as sheetCss.ts for the main datasheet. Layout
// mirrors the client's own Illustrator-made sticker as closely as possible:
// thin card border, stacked label-then-bold-value cells, icon + logo on the
// left, EAN13 barcode bottom-right.
export const STICKER_CSS = `
*{box-sizing:border-box;}
html,body{margin:0;padding:0;}
body{
  padding:20px; background:#fff; font-family:'Inter',sans-serif; color:#111;
}
.sticker{
  width:660px; height:360px;
  border:3px solid #111; border-radius:34px; overflow:hidden;
  display:flex; flex-direction:column; background:#fff;
}
.sticker-main{ display:flex; flex:1; }
.sticker-icon{
  width:160px; flex-shrink:0;
  border-right:1.5px solid #111; border-bottom:1.5px solid #111;
  display:flex; align-items:center; justify-content:center;
}
.sticker-info{ flex:1; display:flex; flex-direction:column; min-width:0; }
.sticker-row{
  flex:1; border-bottom:1.5px solid #111; display:flex; align-items:stretch; min-width:0;
}
.sticker-row:not(.sticker-row-split){ flex-direction:column; justify-content:center; padding:0 26px; }
.sticker-cell{ flex:1; padding:0 26px; display:flex; flex-direction:column; justify-content:center; min-width:0; }
.sticker-cell:first-child{ border-right:1.5px solid #111; }
.k{ font-size:15px; font-weight:500; color:#111; white-space:nowrap; line-height:1; }
.v{ font-size:26px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; line-height:1.2; margin-top:3px; }
.sticker-footer{ height:132px; display:flex; align-items:stretch; }
.sticker-logo{
  width:160px; flex-shrink:0; border-right:1.5px solid #111;
  display:flex; align-items:center; justify-content:center;
}
.sticker-spacer{ flex:1; }
.sticker-barcode{ display:flex; flex-direction:column; align-items:center; justify-content:center; padding-right:28px; }
.sticker-barcode-digits{ font-size:17px; letter-spacing:2px; margin-top:4px; }
`;
