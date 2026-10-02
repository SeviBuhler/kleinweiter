-- Preserve trade rules; only owners can change active, unbid listings.
alter table public.listings drop constraint listings_status_check;
alter table public.listings add constraint listings_status_check check(status in ('active','sold','expired','withdrawn'));
alter function public.market_action(jsonb) rename to market_trade_action;
revoke all on function public.market_trade_action(jsonb) from public,anon,authenticated;

create function public.market_action(p_body jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid; l public.listings; clock bigint; operation text:=p_body->>'action';
begin
 if operation is null or operation not in ('edit','withdraw') then return public.market_trade_action(p_body); end if;
 uid:=public.require_member();
 perform pg_advisory_xact_lock(hashtext(uid::text));
 select * into l from public.listings where id=(p_body->>'id')::uuid for update;
 clock:=floor(extract(epoch from clock_timestamp())*1000);
 if l.id is null or l.seller<>uid then raise exception 'Nur eigene Inserate können verwaltet werden.'; end if;
 if l.status<>'active' or l."end"<=clock then raise exception 'Dieses Inserat ist nicht mehr aktiv.'; end if;
 if l.bid_count<>0 then raise exception 'Nach dem ersten Gebot sind Änderungen und Zurückziehen nicht möglich.'; end if;
 if (p_body->>'revision')::int is distinct from l.revision then raise exception 'Das Inserat wurde inzwischen geändert. Bitte neu laden.'; end if;
 if operation='withdraw' then
  if p_body->'confirm' is distinct from 'true'::jsonb then raise exception 'Bitte das Zurückziehen bestätigen.'; end if;
  update public.listings set status='withdrawn',revision=revision+1 where id=l.id;
  return '{"ok":true,"message":"Dein Inserat wurde zurückgezogen."}';
 end if;
 if p_body->'childrenOnly' is distinct from 'true'::jsonb then raise exception 'Bitte Kinderartikel bestätigen.'; end if;
 if not exists(select 1 from public.uploads u join storage.objects o on o.name=u.path and o.bucket_id='product-images' where u.id=(p_body->>'image')::uuid and u.owner=uid) then raise exception 'Bitte ein eigenes Produktfoto hochladen.'; end if;
 update public.listings set title=trim(p_body->>'title'),description=trim(p_body->>'description'),age=(p_body->>'age')::int,
 category=p_body->>'category',condition=p_body->>'condition',size=trim(p_body->>'size'),location=trim(p_body->>'location'),
 delivery=trim(p_body->>'delivery'),shipping=(p_body->>'shipping')::int,image=(p_body->>'image')::uuid,revision=revision+1 where id=l.id;
 return '{"ok":true,"message":"Dein Inserat wurde aktualisiert."}';
end $$;
revoke all on function public.market_action(jsonb) from public,anon,authenticated;
grant execute on function public.market_action(jsonb) to authenticated;
