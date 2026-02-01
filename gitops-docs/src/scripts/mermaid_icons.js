import mermaid from "mermaid";
import { icons } from "@iconify-json/logos";

mermaid.registerIconPacks([
  {
    name: "logos", // This is the prefix you will use in your diagrams
    icons: icons,
  },
]);
