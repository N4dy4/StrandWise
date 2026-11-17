// Fetches videos (YouTube Data API; TikTok via Tavily + oEmbed) and articles (Tavily) and stores them in
// content_items with source_url (R2). Links out only; nothing is re-hosted.
//
// Secrets: YOUTUBE_API_KEY, TAVILY_API_KEY, SYNC_SECRET
// (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically.)
//
// Call: POST with header `x-sync-secret: <SYNC_SECRET>` and optional JSON body
// { "curlPatterns": ["3B"], "concerns": ["frizz"], "includeProducts": true }.
import { createClient } from "npm:@supabase/supabase-js@2";

const CONCERNS = ["frizz", "breakage", "dandruff", "dryness", "hairLoss"];
const CONCERN_TERMS: Record<string, string> = {
  frizz: "frizz",
  breakage: "breakage",
  dandruff: "dandruff scalp care",
  dryness: "dry hair moisture",
  hairLoss: "hair loss",
};
const DEFAULT_PATTERNS = ["2", "3", "4"]; // curl families
const PRODUCT_SOURCES = [
  { brand: "Camille Rose", domain: "camillerose.com", curlPatterns: [] },
  { brand: "SheaMoisture", domain: "sheamoisture.com", curlPatterns: ["1"] },
  { brand: "SheaMoisture", domain: "sheamoisture.com", curlPatterns: ["2"] },
  { brand: "SheaMoisture", domain: "sheamoisture.com", curlPatterns: ["3"] },
  { brand: "SheaMoisture", domain: "sheamoisture.com", curlPatterns: ["4"] },
  { brand: "Ecoslay", domain: "ecoslay.com", curlPatterns: [] },
  { brand: "The Doux", domain: "thedoux.com", curlPatterns: [] },
] as const;

interface Row {
  type: "video" | "article";
  platform: "youtube" | "tiktok" | "web";
  thumbnail_url: string;
  published_at?: string | null;
  title: string;
  source_name: string;
  source_url: string;
  curl_patterns: string[];
  concerns: string[];
}

interface ProductRow {
  name: string;
  brand: string;
  source_url: string;
  curl_patterns: string[];
  ingredients: string[];
  description: string;
}

const PRODUCT_PATH = /\/(products?|p)\//i;
// Collection pages, bundles and sample sets are not single products.
const NON_PRODUCT_TITLE = /\b(bundle|set|kit|collection|shop all|hair products)\b/i;
const PRODUCT_CATEGORIES = [
  "shampoo",
  "conditioner",
  "leave-in conditioner",
  "curl styling gel cream",
];

// Pulls the INCI list out of a product page's text: the text after an
// "Ingredients" label up to the next blank line, split on top-level commas.
function parseIngredients(text: string): string[] {
  const m = text.match(/ingredients?\s*:?\s*\n?([^\n]{20,2000}(?:\n(?!\s*\n)[^\n]+)*)/i);
  if (!m) return [];
  const list: string[] = [];
  let depth = 0;
  let cur = "";
  for (const ch of m[1].replace(/\s+/g, " ")) {
    if (ch === "(") depth++;
    if (ch === ")") depth = Math.max(0, depth - 1);
    if (ch === "," && depth === 0) {
      list.push(cur);
      cur = "";
    } else cur += ch;
  }
  list.push(cur);
  const seen = new Set<string>();
  const out = list
    .map((i) => i.trim().replace(/[.*†]+$/, "").trim())
    .filter((i) => i.length > 1 && i.length <= 80)
    .filter((i) => !seen.has(i.toLowerCase()) && seen.add(i.toLowerCase()));
  return out.length >= 4 ? out : [];
}

// Tavily's page snippet, trimmed to a short plain-text blurb for the product card.
function cleanDescription(text: string): string {
  const t = text
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/[#*_>`]+/g, "")
    .replace(/\s+/g, " ")
    .trim();
  if (t.length <= 280) return t;
  const cut = t.slice(0, 280);
  return cut.slice(0, Math.max(cut.lastIndexOf(" "), 200)) + "…";
}

function cleanTitle(title: string, brand: string): string {
  const t = title.split(/\s+[|–—-]\s+/)[0].trim();
  return t.toLowerCase().startsWith(brand.toLowerCase())
    ? t.slice(brand.length).replace(/^[\s:–—-]+/, "") || t
    : t;
}

function buildQueries(patterns: string[], concerns: string[]) {
  const out: { q: string; curl: string[]; concerns: string[] }[] = [];
  for (const p of patterns) {
    out.push({ q: `type ${p} hair care routine`, curl: [p], concerns: [] });
    for (const c of concerns) {
      out.push({
        q: `type ${p} hair ${CONCERN_TERMS[c]}`,
        curl: [p],
        concerns: [c],
      });
    }
  }
  return out;
}

async function youtube(q: string, key: string): Promise<Row[] | null> {
  const url = new URL("https://www.googleapis.com/youtube/v3/search");
  url.search = new URLSearchParams({
    part: "snippet",
    type: "video",
    maxResults: "5",
    safeSearch: "strict",
    q,
    key,
  }).toString();
  const res = await fetch(url);
  if (!res.ok) return null;
  const json = await res.json();
  return (json.items ?? []).map((i: any) => ({
    type: "video" as const,
    platform: "youtube" as const,
    thumbnail_url: i.snippet.thumbnails?.high?.url ??
      i.snippet.thumbnails?.medium?.url ?? i.snippet.thumbnails?.default?.url ?? "",
    published_at: i.snippet.publishedAt ?? null,
    title: i.snippet.title,
    source_name: i.snippet.channelTitle,
    source_url: `https://www.youtube.com/watch?v=${i.id.videoId}`,
    curl_patterns: [],
    concerns: [],
  }));
}

async function tavily(q: string, key: string): Promise<Row[] | null> {
  const res = await fetch("https://api.tavily.com/search", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({
      query: q,
      max_results: 5,
      search_depth: "basic",
      exclude_domains: ["tiktok.com"],
    }),
  });
  if (!res.ok) return null;
  const json = await res.json();
  return (json.results ?? []).map((r: any) => ({
    type: "article" as const,
    platform: "web" as const,
    thumbnail_url: "",
    title: r.title,
    source_name: new URL(r.url).hostname.replace(/^www\./, ""),
    source_url: r.url,
    curl_patterns: [],
    concerns: [],
  }));
}

const TIKTOK_VIDEO = /^https:\/\/(www\.)?tiktok\.com\/@[\w.-]+\/video\/\d+/i;

function cleanTikTokTitle(title: string): string {
  return title
    .replace(/\s*\|\s*TikTok\s*$/i, "")
    .replace(/\s+on TikTok\s*$/i, "")
    .replace(/\s+/g, " ")
    .trim();
}

// Best effort: oEmbed gives the real caption and thumbnail; failures are ignored.
async function tiktokOembed(
  url: string,
): Promise<{ title?: string; thumbnail_url?: string }> {
  try {
    const res = await fetch(
      `https://www.tiktok.com/oembed?url=${encodeURIComponent(url)}`,
    );
    if (!res.ok) return {};
    const j = await res.json();
    return { title: j.title, thumbnail_url: j.thumbnail_url };
  } catch {
    return {};
  }
}

async function tiktok(q: string, key: string): Promise<Row[] | null> {
  const res = await fetch("https://api.tavily.com/search", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({
      query: `${q} tiktok`,
      max_results: 8,
      search_depth: "basic",
      include_domains: ["tiktok.com"],
    }),
  });
  if (!res.ok) return null;
  const json = await res.json();
  const hits = (json.results ?? []).filter(
    (r: any) => r.url && r.title && TIKTOK_VIDEO.test(r.url),
  );
  return await Promise.all(hits.map(async (r: any) => {
    const url = r.url.split(/[?#]/)[0];
    const o = await tiktokOembed(url);
    return {
      type: "video" as const,
      platform: "tiktok" as const,
      thumbnail_url: o.thumbnail_url ?? "",
      title: cleanTikTokTitle(o.title || r.title).slice(0, 200) || "TikTok video",
      source_name: "TikTok",
      source_url: url,
      curl_patterns: [],
      concerns: [],
    };
  }));
}

async function tavilyProducts(
  source: (typeof PRODUCT_SOURCES)[number],
  category: string,
  key: string,
): Promise<ProductRow[] | null> {
  const type = source.curlPatterns[0];
  const query = type
    ? `${source.brand} type ${type} hair ${category}`
    : `${source.brand} ${category}`;
  const res = await fetch("https://api.tavily.com/search", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({
      query,
      include_domains: [source.domain],
      max_results: 20,
      search_depth: "advanced",
      include_raw_content: "text",
    }),
  });
  if (!res.ok) return null;

  const json = await res.json();
  return (json.results ?? []).flatMap(
    (r: { title?: string; url?: string; content?: string; raw_content?: string }) => {
      if (!r.title || !r.url) return [];
      try {
        const u = new URL(r.url);
        if (u.hostname.replace(/^www\./, "") !== source.domain) return [];
        if (!PRODUCT_PATH.test(u.pathname)) return [];
        if (NON_PRODUCT_TITLE.test(r.title)) return [];
      } catch {
        return [];
      }
      return [{
        name: cleanTitle(r.title, source.brand),
        brand: source.brand,
        source_url: r.url,
        curl_patterns: [...source.curlPatterns],
        ingredients: parseIngredients(r.raw_content ?? ""),
        description: cleanDescription(r.content ?? ""),
      }];
    },
  );
}

Deno.serve(async (req) => {
  if (req.headers.get("x-sync-secret") !== Deno.env.get("SYNC_SECRET")) {
    return new Response("Unauthorized", { status: 401 });
  }
  const ytKey = Deno.env.get("YOUTUBE_API_KEY");
  const tvKey = Deno.env.get("TAVILY_API_KEY");
  if (!ytKey && !tvKey) {
    return new Response("No API keys configured", { status: 500 });
  }

  const body = await req.json().catch(() => ({}));
  const patterns: string[] = body.curlPatterns ?? DEFAULT_PATTERNS;
  const concerns: string[] = (body.concerns ?? CONCERNS).filter((c: string) =>
    CONCERNS.includes(c)
  );
  const includeProducts = body.includeProducts === true;

  const byUrl = new Map<string, Row>();
  const errors: string[] = [];
  for (const { q, curl, concerns: cs } of buildQueries(patterns, concerns)) {
    const jobs: [string, Promise<Row[] | null>][] = [];
    if (ytKey) jobs.push(["youtube", youtube(q, ytKey)]);
    if (tvKey) jobs.push(["tavily", tavily(q, tvKey)]);
    if (tvKey) jobs.push(["tiktok", tiktok(q, tvKey)]);
    for (const [name, job] of jobs) {
      const rows = await job.catch(() => null);
      if (!rows) {
        errors.push(`${name}: "${q}" failed`);
        continue;
      }
      for (const r of rows) {
        const existing = byUrl.get(r.source_url);
        if (existing) {
          existing.curl_patterns = [...new Set([...existing.curl_patterns, ...curl])];
          existing.concerns = [...new Set([...existing.concerns, ...cs])];
        } else {
          byUrl.set(r.source_url, { ...r, curl_patterns: curl, concerns: cs });
        }
      }
    }
  }

  const rows = [...byUrl.values()];
  if (rows.length > 0) {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { error } = await supabase
      .from("content_items")
      .upsert(rows, { onConflict: "source_url" });
    if (error) return new Response(error.message, { status: 500 });
  }

  const productsByUrl = new Map<string, ProductRow>();
  if (includeProducts && tvKey) {
    const jobs = PRODUCT_SOURCES.flatMap((source) =>
      PRODUCT_CATEGORIES.map(async (category) => ({
        label: `${source.brand} ${category}`,
        products: await tavilyProducts(source, category, tvKey).catch(() => null),
      }))
    );
    for (const { label, products } of await Promise.all(jobs)) {
      if (!products) {
        errors.push(`${label} products failed`);
        continue;
      }
      for (const product of products) {
        const existing = productsByUrl.get(product.source_url);
        if (existing) {
          existing.curl_patterns = [
            ...new Set([...existing.curl_patterns, ...product.curl_patterns]),
          ];
          if (existing.ingredients.length === 0) {
            existing.ingredients = product.ingredients;
          }
          if (!existing.description) existing.description = product.description;
        } else {
          productsByUrl.set(product.source_url, product);
        }
      }
    }
  }
  const products = [...productsByUrl.values()];
  if (products.length > 0) {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: saved, error } = await supabase
      .from("products")
      .upsert(
        products.map(({ ingredients: _i, ...row }) => row),
        { onConflict: "source_url" },
      )
      .select("id, source_url");
    if (error) return new Response(error.message, { status: 500 });

    const idByUrl = new Map(saved.map((p) => [p.source_url, p.id]));
    for (const product of products) {
      const productId = idByUrl.get(product.source_url);
      if (!productId || product.ingredients.length === 0) continue;

      const { error: ingError } = await supabase
        .from("ingredients")
        .upsert(
          product.ingredients.map((name) => ({ name })),
          { onConflict: "name", ignoreDuplicates: true },
        );
      if (ingError) {
        errors.push(`ingredients for ${product.source_url}: ${ingError.message}`);
        continue;
      }
      const { data: ingRows, error: lookupError } = await supabase
        .from("ingredients")
        .select("id, name")
        .in("name", product.ingredients);
      if (lookupError || !ingRows) {
        errors.push(`ingredient lookup for ${product.source_url} failed`);
        continue;
      }
      const idByName = new Map(ingRows.map((i) => [i.name, i.id]));
      const links = product.ingredients.flatMap((name, index) => {
        const ingredientId = idByName.get(name);
        return ingredientId
          ? [{ product_id: productId, ingredient_id: ingredientId, position: index + 1 }]
          : [];
      });
      await supabase.from("product_ingredients").delete().eq("product_id", productId);
      const { error: linkError } = await supabase
        .from("product_ingredients")
        .insert(links);
      if (linkError) errors.push(`links for ${product.source_url}: ${linkError.message}`);
    }
  }

  return Response.json({
    contentUpserted: rows.length,
    productsUpserted: products.length,
    errors,
  });
});
