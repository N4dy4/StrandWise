# StrandWise — App Plan

## 1. Product Definition

**StrandWise** is a hair care companion app that builds personalized routines, educates users with cited sources, and helps them understand ingredients.

### Core features

| # | Feature | Notes |
|---|---------|-------|
| F1 | Hair profile onboarding quiz | Curl pattern (1A–4C), porosity, density, scalp type, concerns (frizz, breakage, dandruff), goals |
| F2 | Personalized routine builder | Wash-day + daily routines with steps, frequency, and reminders |
| F3 | Content discovery | Videos + articles matched to hair type, every item cited with a source link (R2) |
| F4 | Ingredient & product knowledge base | Search any ingredient/product → what it does, who it suits, flags (sulfates, silicones, drying alcohols) |
| F5 | Progress tracking | Photo log + hair health journal to feed personalization |

### Design requirements

| Req | Description |
|-----|-------------|
| R1 | Pink, friendly, approachable UI — soft palette, rounded components, illustrations |
| R2 | Web-sourced info and products with linked citations |
| R3 | Offline-first routine tracking — routines and reminders must work without a connection |
| R4 | Privacy by default — hair photos and profile data never shared; clear "not medical advice" disclaimers |

---

## 2. Architecture

```
Flutter app (iOS -> Android)
        |
   REST API (FastAPI or NestJS)
        |
  +-----+--------------+
PostgreSQL   Object storage   External APIs
(profiles,   (progress        (YouTube Data API,
routines,    photos)           search API, product data)
ingredients)
        |
Recommendation service (rule-based v1 -> ML v2)
```

- **Frontend:** Flutter — one codebase covers iOS now and Android later.
- **Backend:** Supabase (managed Postgres + auth + photo storage in one). Satisfies the "Postgres SQL" requirement without DevOps overhead.
- **Content/citations:** YouTube Data API for videos; Tavily or SerpAPI for articles/products. Store results in Postgres with source URLs so citations are permanent.
- **AI model:**
  - **v1 — rule-based engine:** hair type x concerns -> routine templates. There is no training data at launch, so "ML" on day one would be fake.
  - **v2 — ML personalization:** once users log routine adherence + progress, rank/reorder steps and products with collaborative filtering or an embedding model.

### Key data tables

`users`, `hair_profiles`, `routines`, `routine_steps`, `ingredients`, `products`, `product_ingredients`, `content_items` (with `source_url`), `progress_logs`, `reminders`

---

## 3. Roadmap

| Phase | Scope | Exit criteria |
|-------|-------|---------------|
| **0 — Foundation (wk 1–2)** | Repo scaffold, CI, Supabase project, design tokens (pink theme) | App builds; auth works |
| **1 — MVP (wk 3–8)** | Onboarding quiz, hair profile, rule-based routines, reminders, ingredient glossary | TestFlight build; 10 beta users complete onboarding |
| **2 — Content (wk 9–12)** | Video/article feed with citations, product search w/ ingredient flags | Feed personalized by hair type |
| **3 — Intelligence (wk 13+)** | Progress photos, ML personalization v1, Android release | Retention measured; model v1 live |

---

## 4. Testing & Maintenance

- **Unit:** routine-engine logic, ingredient flagging rules (pure functions — easy wins)
- **Widget/integration:** onboarding flow, reminder scheduling
- **Beta:** TestFlight cohort of real users across hair types 1A–4C
- **Maintenance:** monthly content-source validation (dead links break the R2 promise), ingredient DB updates, dependency updates via Dependabot

---

## 5. Risks to Watch

1. **Content ToS** — cite and link out; don't re-host videos/articles.
2. **Cold start** — don't promise "AI-optimized" until v2; market v1 as "expert-built routines."
3. **Medical boundary** — hair/scalp advice needs clear disclaimers (esp. hair loss topics).
