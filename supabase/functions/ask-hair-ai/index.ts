// Small-LLM assistant for "Ask anything" and hairstyle ideas. The model key
// stays server-side; the app only sends the question and the hair profile.
//
// Secrets: AI_API_KEY (free Groq key from https://console.groq.com/keys)
// Optional: AI_MODEL (default openai/gpt-oss-20b) and AI_BASE_URL (default
// Groq's OpenAI-compatible endpoint; any OpenAI-compatible provider works,
// e.g. Gemini's https://generativelanguage.googleapis.com/v1beta/openai).
// (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided automatically.)
//
// POST { mode: "ask" | "styles", question?, profile, preferences? }
// -> ask:    { answer, products: [{ name, brand, source_url }], disclaimer }
// -> styles: { styles: [{ name, why, care }], disclaimer }
// Recommended products are validated against the products table so every one
// carries its permanent source_url citation (R2); the model can't invent them.
import { createClient } from "npm:@supabase/supabase-js@2";

const BASE_URL = (Deno.env.get("AI_BASE_URL") ??
  "https://api.groq.com/openai/v1").replace(/\/$/, "");
const ENDPOINT = `${BASE_URL}/chat/completions`;
const DISCLAIMER =
  "AI-generated, not medical advice. For hair loss or scalp conditions, see a doctor or dermatologist.";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });

const clip = (v: unknown, n: number) => String(v ?? "").slice(0, n);

async function chat(system: string, user: string): Promise<any> {
  const res = await fetch(ENDPOINT, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("AI_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("AI_MODEL") ?? "openai/gpt-oss-20b",
      temperature: 0.4,
      max_tokens: 1500, // reasoning models spend part of this thinking
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: system },
        { role: "user", content: user },
      ],
    }),
  });
  if (!res.ok) throw new Error(`model ${res.status}`);
  const data = await res.json();
  return JSON.parse(data.choices?.[0]?.message?.content ?? "{}");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  if (!Deno.env.get("AI_API_KEY")) {
    return json({ error: "AI is not configured" }, 503);
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
  const mode = body.mode === "styles" ? "styles" : "ask";
  const p = body.profile ?? {};
  const concerns = (Array.isArray(p.concerns) ? p.concerns : [])
    .slice(0, 5).map((c: unknown) => clip(c, 20)).join(", ") || "none";
  const profile = [
    `Curl pattern: ${clip(p.curlPattern, 4)}`,
    `Porosity: ${clip(p.porosity, 10)}`,
    `Density: ${clip(p.density, 10)}`,
    `Scalp: ${clip(p.scalp, 10)}`,
    `Concerns: ${concerns}`,
    `Strand size: ${clip(p.strandSize, 10)}`,
    `Color-treated: ${p.colorTreated === true ? "yes" : "no"}`,
    `Wash frequency: ${clip(p.washFrequency, 12) || "unknown"}`,
    `Usual styles: ${
      (Array.isArray(p.styling) ? p.styling : []).slice(0, 5).map((s: unknown) =>
        clip(s, 20)
      ).join(", ") || "unknown"
    }`,
  ].join("\n");

  const base =
    "You are a friendly, concise hair-care assistant. Give practical, " +
    "evidence-aware advice for the user's hair profile. Never diagnose; for " +
    "hair loss or scalp conditions advise seeing a doctor. Reply with JSON only.";

  try {
    if (mode === "styles") {
      const prefs = clip(body.preferences, 300) || "none stated";
      const out = await chat(
        base,
        `Hair profile:\n${profile}\nPreferences: ${prefs}\n\n` +
          `Recommend 4 hairstyles. JSON: {"styles":[{"name":"","why":"","care":""}]} ` +
          `where why is one sentence tying it to the profile and care is one sentence of upkeep.`,
      );
      const styles = (Array.isArray(out.styles) ? out.styles : []).slice(0, 6)
        .map((s: any) => ({
          name: clip(s.name, 80),
          why: clip(s.why, 300),
          care: clip(s.care, 300),
        })).filter((s: any) => s.name);
      return json({ styles, disclaimer: DISCLAIMER });
    }

    const question = clip(body.question, 500).trim();
    if (!question) return json({ error: "Question required" }, 400);

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: catalog } = await db
      .from("products")
      .select("id, name, brand, source_url, curl_patterns")
      .limit(150);
    const family = clip(p.curlPattern, 4).charAt(0);
    const products = (catalog ?? []).filter((r: any) =>
      !r.curl_patterns?.length || r.curl_patterns.includes(family)
    ).slice(0, 60);

    const out = await chat(
      base,
      `Hair profile:\n${profile}\n\nQuestion: ${question}\n\n` +
        `Catalog (id | brand | name):\n` +
        products.map((r: any) => `${r.id} | ${r.brand} | ${r.name}`).join("\n") +
        `\n\nJSON: {"answer":"<=120 words","product_ids":["up to 3 catalog ids, only if the question calls for products"]}`,
    );
    const byId = new Map(products.map((r: any) => [r.id, r]));
    const picked = (Array.isArray(out.product_ids) ? out.product_ids : [])
      .map((id: string) => byId.get(id)).filter(Boolean).slice(0, 3)
      .map((r: any) => ({
        name: r.name,
        brand: r.brand,
        source_url: r.source_url,
      }));
    return json({
      answer: clip(out.answer, 1200),
      products: picked,
      disclaimer: DISCLAIMER,
    });
  } catch (e) {
    console.error(e);
    return json({ error: "AI request failed" }, 502);
  }
});
