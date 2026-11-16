-- Removes collection pages, bundles, and sample sets that an earlier sync
-- imported as products. sync-content now filters these out.
delete from public.products
where name ~* '\m(bundle|set|kit|collection|shop all|hair products|combo)\M'
   or name ~* '^type \d$';
