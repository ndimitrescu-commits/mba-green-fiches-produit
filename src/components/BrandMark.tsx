import { createElement } from "react";

export default function BrandMark({ size = 26, color = "var(--deepgreen)" }: { size?: number; color?: string }) {
  return createElement(
    "svg",
    { width: size, height: size, viewBox: "0 0 32 32", fill: "none", xmlns: "http://www.w3.org/2000/svg", "aria-hidden": "true" },
    createElement("path", { d: "M10 6H22L26 26H6L10 6Z", fill: color })
    );
}
