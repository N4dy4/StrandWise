// Fetches videos (YouTube Data API) and articles (Tavily) and stores them in
// content_items with source_url (R2). Links out only; nothing is re-hosted.
//
// Secrets: YOUTUBE_API_KEY, TAVILY_API_KEY, SYNC_SECRET
// (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically.)
//
// Call: POST with header `x-sync-secret: <SYNC_SECRET>` and optional JSON body
// { "curlPatterns": ["3B"], "concerns": ["frizz"] }.
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

interface Row {
  type: "video" | "article";
  title: string;
  source_name: string;
  source_url: string;
  curl_patterns: string[];
  concerns: string[];
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
    body: JSON.stringify({ query: q, max_results: 5, search_depth: "basic" }),
  });
  if (!res.ok) return null;
  const json = await res.json();
  return (json.results ?? []).map((r: any) => ({
    type: "article" as const,
    title: r.title,
    source_name: new URL(r.url).hostname.replace(/^www\./, ""),
    source_url: r.url,
    curl_patterns: [],
    concerns: [],
  }));
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

  const byUrl = new Map<string, Row>();
  const errors: string[] = [];
  for (const { q, curl, concerns: cs } of buildQueries(patterns, concerns)) {
    const jobs: [string, Promise<Row[] | null>][] = [];
    if (ytKey) jobs.push(["youtube", youtube(q, ytKey)]);
    if (tvKey) jobs.push(["tavily", tavily(q, tvKey)]);
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

  return Response.json({ upserted: rows.length, errors });
});
