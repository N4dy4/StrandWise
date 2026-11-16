---
name: strandwise-database-management
description: Organize web-scraped StrandWise data (content, products, ingredients) and manage Supabase migrations, RLS, deduplication, and citations.
---

# StrandWise Database Management

Use this skill when ingesting, sorting, cleaning, or migrating StrandWise data in
Supabase Postgres. Product spec: `docs/PLAN.md`; setup: `docs/SUPABASE_SETUP.md`.

## Where scraped data goes

| Source | Table | Key fields |
|--------|-------|-----------|
| YouTube / Tavily articles | `content_items` | `type` (`video`/`article`), `title`, `source_name`, `source_url`, `curl_patterns`, `concerns` |
| Brand product pages (Tavily) | `products` | `name`, `brand`, `source_url`, `curl_patterns` |
| Ingredient lists | `ingredients` + `product_ingredients` | unique `name`, optional `flag`, label-order `position` |

Ingestion lives in `supabase/functions/sync-content/index.ts` (secrets only in
Supabase secrets). Local-mode sample data in `app/lib/data/local_content_repository.dart`
must stay consistent with seeded rows.

## Sorting and classification rules

- **Citation (R2):** every `content_items` and `products` row needs a non-empty,
  original `source_url`. Never strip, shorten, or replace it; never re-host content.
- **Dedup:** upsert on `source_url` (unique on both tables). Merge `curl_patterns`
  and `concerns` arrays (set union) when the same URL appears twice.
- **Hair type tags:** use curl families `1`–`4` or exact types (`3B`). Source pages
  that are type-specific (e.g. SheaMoisture `type-3`) tag that family; brand-wide
  pages stay untagged (`{}`) rather than guessed.
- **Concerns:** only `frizz`, `breakage`, `dandruff`, `dryness`, `hairLoss`.
- **Brand:** normalize to one canonical spelling per brand (`Camille Rose`,
  `SheaMoisture`, `Mielle`, `Ecoslay`, `The Doux`).
- **Ingredients:** keep INCI label order in `position`; flags are only
  `sulfate`, `silicone`, `dryingAlcohol` and must not flag fatty alcohols
  (cetyl/cetearyl) or magnesium sulfate (see `IngredientFlagger`).
- Only store product facts found on the source page; leave unknown fields empty.

## Managing the database

- Schema changes go in new numbered files in `supabase/migrations/`
  (`NNNN_description.sql`); never edit applied migrations. Make them idempotent
  (`if not exists`, `on conflict`).
- Every table keeps RLS enabled (R4). Catalog tables are read-only for
  `anon`/`authenticated`; writes only via the service role (Edge Functions).
  User tables (profiles, routines, progress logs, reminders) get per-user policies.
- Never commit keys. Service-role and API keys stay in Supabase secrets or
  `--dart-define`.
- After ingestion, sanity-check with SQL, e.g.:
  ```sql
  select count(*) from products where source_url = '';             -- expect 0
  select source_url, count(*) from content_items group by 1 having count(*) > 1; -- expect none
  select brand, count(*) from products group by brand order by brand;
  ```
- Re-run sync monthly and validate links (dead links break R2); remove or
  replace rows whose `source_url` no longer resolves.

## Verification

When Dart models or queries change, run from `app/`: `flutter analyze` and
`flutter test`. Keep `Product`/`ContentItem` models and repository `select`
columns in sync with migrations.
