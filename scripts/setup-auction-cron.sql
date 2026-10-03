-- Hosted Supabase only, run as postgres after the settlement migration.
-- Reapplying this named schedule updates it rather than creating duplicates.
create extension if not exists pg_cron;
select cron.schedule('kleinweiter-auction-settlement','* * * * *','select public.settle_due_auctions();');
select jobid,jobname,schedule,command,active from cron.job where jobname='kleinweiter-auction-settlement';
