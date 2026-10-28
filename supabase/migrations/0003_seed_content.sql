-- Sample seed data. Replace source URLs with curated, validated links before launch.

insert into public.content_items (type, title, source_name, source_url, curl_patterns, concerns) values
  ('article', 'Curly hair care basics', 'NaturallyCurly', 'https://www.naturallycurly.com/', '{2,3,4}', '{}'),
  ('article', 'Managing breakage on coily hair', 'NaturallyCurly', 'https://www.naturallycurly.com/', '{4}', '{breakage}'),
  ('article', 'Dandruff and your scalp', 'American Academy of Dermatology', 'https://www.aad.org/', '{}', '{dandruff}'),
  ('video', 'Taming frizz on wavy hair', 'YouTube', 'https://www.youtube.com/', '{2}', '{frizz}');

insert into public.ingredients (name, flag) values
  ('Water', null),
  ('Sodium Lauryl Sulfate', 'sulfate'),
  ('Dimethicone', 'silicone'),
  ('Alcohol Denat.', 'dryingAlcohol'),
  ('Cetyl Alcohol', null),
  ('Cetearyl Alcohol', null),
  ('Shea Butter', null),
  ('Glycerin', null)
on conflict (name) do nothing;

with p as (
  insert into public.products (name, brand, source_url) values
    ('Sample Clarifying Shampoo', 'Example Brand', 'https://www.example.com/'),
    ('Sample Moisture Conditioner', 'Example Brand', 'https://www.example.com/')
  returning id, name
)
insert into public.product_ingredients (product_id, ingredient_id, position)
select p.id, i.id, v.pos
from (values
  ('Sample Clarifying Shampoo', 'Water', 1),
  ('Sample Clarifying Shampoo', 'Sodium Lauryl Sulfate', 2),
  ('Sample Clarifying Shampoo', 'Dimethicone', 3),
  ('Sample Clarifying Shampoo', 'Alcohol Denat.', 4),
  ('Sample Clarifying Shampoo', 'Cetyl Alcohol', 5),
  ('Sample Moisture Conditioner', 'Water', 1),
  ('Sample Moisture Conditioner', 'Cetearyl Alcohol', 2),
  ('Sample Moisture Conditioner', 'Shea Butter', 3),
  ('Sample Moisture Conditioner', 'Glycerin', 4)
) as v(pname, iname, pos)
join p on p.name = v.pname
join public.ingredients i on i.name = v.iname;
