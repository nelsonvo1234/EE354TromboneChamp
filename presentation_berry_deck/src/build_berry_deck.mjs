import {
  Presentation,
  PresentationFile,
  column,
  row,
  grid,
  panel,
  text,
  shape,
  rule,
  fill,
  hug,
  fixed,
  wrap,
  grow,
  fr,
} from "@oai/artifact-tool";
import { writeFile } from "node:fs/promises";

const W = 1920;
const H = 1080;
const deck = Presentation.create({ slideSize: { width: W, height: H } });

const C = {
  ink: "#F8FAFC",
  muted: "#B8C7D9",
  dim: "#7890AA",
  bg0: "#08111F",
  bg1: "#0E1C2F",
  bg2: "#132A45",
  cyan: "#22D3EE",
  berry: "#F43F5E",
  berryDark: "#9F1239",
  leaf: "#34D399",
  gold: "#FBBF24",
  solid: "#66E0A3",
  spike: "#E2E8F0",
  line: "#2E4A68",
};

function slideRoot(children, opts = {}) {
  const slide = deck.slides.add();
  slide.compose(
    panel(
      {
        name: "slide-root",
        width: fill,
        height: fill,
        fill: C.bg0,
        padding: { x: 86, y: 68 },
      },
      column(
        {
          name: "slide-flow",
          width: fill,
          height: fill,
          gap: opts.gap ?? 36,
        },
        children,
      ),
    ),
    { frame: { left: 0, top: 0, width: W, height: H }, baseUnit: 8 },
  );
  return slide;
}

async function saveAnyBlob(blob, path) {
  if (blob && typeof blob.save === "function") {
    await blob.save(path);
    return;
  }
  if (blob && typeof blob.arrayBuffer === "function") {
    await writeFile(path, Buffer.from(await blob.arrayBuffer()));
    return;
  }
  throw new Error(`Cannot save unsupported blob to ${path}`);
}

function titleBlock(title, subtitle) {
  return column(
    { name: "title-stack", width: fill, height: hug, gap: 14 },
    [
      text(title, {
        name: "slide-title",
        width: fill,
        height: hug,
        style: { fontSize: 58, bold: true, color: C.ink, fontFace: "Aptos Display" },
      }),
      subtitle
        ? text(subtitle, {
            name: "slide-subtitle",
            width: wrap(1280),
            height: hug,
            style: { fontSize: 25, color: C.muted, fontFace: "Aptos" },
          })
        : rule({ name: "title-rule", width: fixed(180), stroke: C.cyan, weight: 5 }),
    ],
  );
}

function label(value, color = C.muted) {
  return text(value, {
    name: `label-${value.slice(0, 12)}`,
    width: fill,
    height: hug,
    style: { fontSize: 22, color, fontFace: "Aptos", bold: true },
  });
}

function note(value) {
  return text(value, {
    name: `note-${value.slice(0, 12)}`,
    width: fill,
    height: hug,
    style: { fontSize: 24, color: C.muted, fontFace: "Aptos" },
  });
}

function codeLine(value, accent = C.cyan) {
  return panel(
    {
      name: `code-${value.slice(0, 10)}`,
      width: fill,
      height: hug,
      padding: { x: 18, y: 10 },
      fill: "#0B1626",
      line: { color: "#1D3551", weight: 1 },
      borderRadius: 6,
    },
    text(value, {
      name: `code-text-${value.slice(0, 10)}`,
      width: fill,
      height: hug,
      style: { fontSize: 24, color: accent, fontFace: "Cascadia Mono" },
    }),
  );
}

function berryPixel(size = 28) {
  const sq = (fillColor) => shape({ width: fixed(size), height: fixed(size), fill: fillColor });
  const empty = shape({ width: fixed(size), height: fixed(size), fill: "#00000000" });
  return column(
    { name: "berry-pixel", width: hug, height: hug, gap: 0 },
    [
      row({ width: hug, height: hug, gap: 0 }, [empty, sq(C.leaf), sq(C.leaf), empty]),
      row({ width: hug, height: hug, gap: 0 }, [sq(C.berry), sq(C.berry), sq(C.berry), sq(C.berry)]),
      row({ width: hug, height: hug, gap: 0 }, [sq(C.berry), sq(C.berryDark), sq(C.berry), sq(C.berry)]),
      row({ width: hug, height: hug, gap: 0 }, [empty, sq(C.berry), sq(C.berry), empty]),
    ],
  );
}

function tileGrid({ berryAt = [], playerAt = [], w = 8, h = 5, size = 42 }) {
  const cells = [];
  for (let y = 0; y < h; y++) {
    const rowCells = [];
    for (let x = 0; x < w; x++) {
      const isBerry = berryAt.some(([bx, by]) => x >= bx && x <= bx + 1 && y >= by && y <= by + 1);
      const isPlayer = playerAt.some(([px, py]) => x === px && y === py);
      rowCells.push(
        shape({
          name: `cell-${x}-${y}`,
          width: fixed(size),
          height: fixed(size),
          fill: isPlayer ? C.cyan : isBerry ? C.berry : "#0A1728",
          line: { color: "#284762", weight: 1 },
        }),
      );
    }
    cells.push(row({ width: hug, height: hug, gap: 0 }, rowCells));
  }
  return column({ name: "tile-grid", width: hug, height: hug, gap: 0 }, cells);
}

function arrow(labelText, color = C.gold) {
  return column(
    { name: `arrow-${labelText}`, width: fixed(180), height: hug, gap: 0, align: "center" },
    [
      text("→", { width: fill, height: hug, style: { fontSize: 42, color, bold: true } }),
      text(labelText, { width: fill, height: hug, style: { fontSize: 14, color: C.dim, align: "center" } }),
    ],
  );
}

function infoPanel(title, body, accent = C.cyan) {
  return panel(
    {
      name: `info-${title}`,
      width: fill,
      height: hug,
      padding: { x: 28, y: 24 },
      fill: "#0B1626",
      line: { color: "#224466", weight: 1 },
      borderRadius: 8,
    },
    column(
      { width: fill, height: hug, gap: 12 },
      [
        text(title, { width: fill, height: hug, style: { fontSize: 28, bold: true, color: accent } }),
        text(body, { width: fill, height: hug, style: { fontSize: 22, color: C.muted } }),
      ],
    ),
  );
}

// 1 Cover
slideRoot(
  [
    row(
      { name: "cover-row", width: fill, height: fill, gap: 56, align: "center" },
      [
        column(
          { name: "cover-copy", width: grow(1.1), height: hug, gap: 28 },
          [
            text("Berry Collection System", {
              name: "cover-title",
              width: fill,
              height: hug,
              style: { fontSize: 82, bold: true, color: C.ink, fontFace: "Aptos Display" },
            }),
            text("How the Artix-7 game tracks, draws, collects, scores, celebrates, and resets strawberries.", {
              name: "cover-subtitle",
              width: wrap(980),
              height: hug,
              style: { fontSize: 31, color: C.muted, fontFace: "Aptos" },
            }),
            rule({ name: "cover-rule", width: fixed(320), stroke: C.berry, weight: 7 }),
          ],
        ),
        panel(
          { name: "cover-art-stage", width: fixed(560), height: fixed(560), padding: 36, fill: "#0B1626", borderRadius: 8 },
          column({ width: fill, height: fill, gap: 24, align: "center", justify: "center" }, [
            berryPixel(58),
            text("5 persistent berries · 1-cycle score pulse", {
              name: "cover-chip",
              width: fill,
              height: hug,
              style: { fontSize: 25, bold: true, color: C.gold, align: "center" },
            }),
          ]),
        ),
      ],
    ),
  ],
  { gap: 0 },
);

// 2 One sentence architecture
slideRoot([
  titleBlock("The berry system is a tiny state machine", "VGA rendering asks “what tile is here?” while gameplay asks “did the player touch a live berry?”"),
  row({ name: "architecture-flow", width: fill, height: fill, gap: 22, align: "center" }, [
    infoPanel("Tile map", "`tile_at_tile()` marks live berry tiles as `STRAWBERRY`.", C.berry),
    arrow("draws"),
    infoPanel("Sprite ROM", "VGA samples the strawberry frame and outputs 12-bit RGB.", C.leaf),
    arrow("touches"),
    infoPanel("Berry FSM", "A touched berry clears one bit and emits `collect_berry`.", C.gold),
    arrow("scores"),
    infoPanel("Score", "One pulse increments the SSD counter by exactly one.", C.cyan),
  ]),
]);

// 3 Coordinates and footprints
slideRoot([
  titleBlock("Each strawberry is a 2×2 tile footprint", "The coordinate is the top-left tile; the mask covers four tiles so the visual and collectible area match."),
  row({ width: fill, height: fill, gap: 60, align: "center" }, [
    panel(
      { width: fixed(720), height: hug, padding: 28, fill: "#0B1626", borderRadius: 8, line: { color: "#224466", weight: 1 } },
      column({ width: fill, height: hug, gap: 20, align: "center" }, [
        tileGrid({ berryAt: [[2, 1]], playerAt: [[5, 3]], w: 8, h: 5, size: 58 }),
        text("A berry at (2, 1) occupies (2..3, 1..2)", {
          width: fill,
          height: hug,
          style: { fontSize: 24, color: C.muted, align: "center" },
        }),
      ]),
    ),
    column({ width: fill, height: hug, gap: 16 }, [
      codeLine("localparam BERRY_COUNT = 5;", C.gold),
      codeLine("BERRY0_X, BERRY0_Y  // top-left tile", C.cyan),
      codeLine("tx >= BERRY_X && tx <= BERRY_X + 1", C.leaf),
      note("The `berries_present` register controls which of those 2×2 footprints still exists."),
    ]),
  ]),
]);

// 4 Persistent register
slideRoot([
  titleBlock("`berries_present` is the source of truth", "Five bits represent five strawberries. Reset or spike restores all bits; collection clears just the touched berry."),
  grid(
    { name: "bit-grid", width: fill, height: fill, columns: [fr(1), fr(1)], columnGap: 54, rowGap: 20 },
    [
      column({ width: fill, height: hug, gap: 18 }, [
        label("Before collection", C.gold),
        codeLine("berries_present = 5'b11111", C.leaf),
        note("All five strawberries draw and can be collected."),
      ]),
      column({ width: fill, height: hug, gap: 18 }, [
        label("After touching berry 2", C.gold),
        codeLine("touched_berries = 5'b00100", C.berry),
        codeLine("berries_present <= berries_present & ~touched_berries", C.cyan),
        note("Only berry 2 disappears; the other bits stay live."),
      ]),
    ],
  ),
]);

// 5 Touch detection
slideRoot([
  titleBlock("Collection checks both current and next corners", "That avoids missing berries during dashes and keeps visual contact aligned with gameplay contact."),
  row({ width: fill, height: fill, gap: 48, align: "center" }, [
    panel(
      { width: fixed(700), height: hug, padding: 28, fill: "#0B1626", borderRadius: 8 },
      column({ width: fill, height: hug, gap: 18, align: "center" }, [
        tileGrid({ berryAt: [[4, 1]], playerAt: [[2, 2], [5, 2]], w: 8, h: 5, size: 56 }),
        text("current corners + next corners", { width: fill, height: hug, style: { fontSize: 25, color: C.ink, bold: true, align: "center" } }),
      ]),
    ),
    column({ width: fill, height: hug, gap: 14 }, [
      codeLine("berry_mask(player_left, player_top)", C.cyan),
      codeLine("berry_mask(player_right, player_bottom)", C.cyan),
      codeLine("berry_mask(left, top) | berry_mask(right, bottom)", C.leaf),
      rule({ width: fixed(360), stroke: C.berry, weight: 4 }),
      text("All masks OR together into `touched_berries`.", {
        width: fill,
        height: hug,
        style: { fontSize: 31, bold: true, color: C.ink },
      }),
    ]),
  ]),
]);

// 6 FSM
slideRoot([
  titleBlock("The FSM turns overlap into one score pulse", "Without the pulse, the score would climb every clock while the player overlaps the berry."),
  row({ width: fill, height: fill, gap: 36, align: "center" }, [
    infoPanel("BERRIES_READY", "Wait until `(berries_present & touched_berries)` is nonzero.", C.cyan),
    arrow("overlap"),
    infoPanel("BERRIES_UPDATE", "Clear touched bits and set `collect_pulse` for one clock.", C.berry),
    arrow("next"),
    infoPanel("BERRIES_READY", "Return to waiting. The score saw exactly one pulse.", C.leaf),
  ]),
]);

// 7 Rendering and win behavior
slideRoot([
  titleBlock("Rendering and win behavior stay separate from collection", "The visible sprite is a presentation of state; the FSM owns game truth."),
  grid(
    { width: fill, height: fill, columns: [fr(1), fr(1)], columnGap: 48, rowGap: 24 },
    [
      infoPanel("Draw priority", "celebration → Madeline → strawberry → spike → solid tile → background", C.gold),
      infoPanel("Sprite scaling", "The strawberry ROM is 16×16; VGA maps it across a 32×32, 2×2-tile area.", C.berry),
      infoPanel("Score", "`collect_berry` increments the SSD counter. Reset or spike clears it.", C.cyan),
      infoPanel("Win reset", "`all_berries_collected` starts a 10-second timer, shows celebration, then resets the game.", C.leaf),
    ],
  ),
]);

const pptx = await PresentationFile.exportPptx(deck);
await saveAnyBlob(pptx, "output/berry-system-deck.pptx");

for (let i = 0; i < deck.slides.count; i++) {
  const slide = deck.slides.getItem(i);
  const png = await slide.export({ format: "png" });
  await saveAnyBlob(png, `scratch/slide-${String(i + 1).padStart(2, "0")}.png`);
}

const layout = deck.inspect({ format: "layout" });
await writeFile("scratch/layout.json", JSON.stringify(layout, null, 2));

console.log(JSON.stringify({ slides: deck.slides.count, pptx: "output/berry-system-deck.pptx" }, null, 2));
