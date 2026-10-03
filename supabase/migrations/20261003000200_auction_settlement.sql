-- Private scheduler entry point. Public feeds retain their existing fallback.
create index listings_due_idx on public.listings("end",id) where status='active';
create function public.settle_due_auctions() returns integer language plpgsql security definer set search_path='' as $$
declare settled integer; cutoff bigint:=floor(extract(epoch from clock_timestamp())*1000);
begin
 -- Bounded batches and SKIP LOCKED avoid holding up bids or another worker.
 with due as materialized (
  select id from public.listings where status='active' and "end"<=cutoff
  order by "end",id limit 500 for update skip locked
 ), changed as (
  update public.listings l set status=case when l.bidder is null then 'expired' else 'sold' end
  from due where l.id=due.id and l.status='active' and l."end"<=cutoff returning l.id
 ) select count(*) into settled from changed;
 -- Existing transactional triggers create the order and notifications once.
 return settled;
end $$;
revoke all on function public.settle_due_auctions() from public,anon,authenticated;
