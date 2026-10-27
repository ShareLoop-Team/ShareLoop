-- ShareLoop workflow functions: the only way to move items, requests and
-- exchanges between states, plus admin moderation. Each runs as its owner
-- (security definer) and checks the caller itself, so clients never need
-- write access to status columns.
--
-- Item:     active -> pending_handover -> completed
--                 \<- (cancel_exchange) <-/
-- Request:  pending -> approved | rejected
-- Exchange: pending -> completed (both parties confirmed) | cancelled

-- Raises unless the caller is a signed-in, non-suspended user; returns
-- their Firebase UID.
create or replace function private.require_active_user()
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  me text := public.requesting_user_id();
begin
  if me is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;
  if not private.is_active_user() then
    raise exception 'Your account is not active' using errcode = '42501';
  end if;
  return me;
end;
$$;

create or replace function private.require_admin()
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  me text := private.require_active_user();
begin
  if not private.is_admin() then
    raise exception 'Admins only' using errcode = '42501';
  end if;
  return me;
end;
$$;

revoke all on function private.require_active_user() from public, anon, authenticated;
revoke all on function private.require_admin() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Registration
-- ---------------------------------------------------------------------------

-- Creates the caller's profile and contact details together, right after
-- Firebase sign-up. The email comes from the verified token, not the
-- client. Fails if the profile already exists.
create or replace function public.create_my_profile(
  p_display_name text,
  p_district text,
  p_city text,
  p_phone text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := public.requesting_user_id();
  token_email text := auth.jwt() ->> 'email';
  result public.profiles%rowtype;
begin
  if me is null then
    raise exception 'Not signed in' using errcode = '42501';
  end if;
  if coalesce(token_email, '') = '' then
    raise exception 'Your account has no email address' using errcode = 'P0001';
  end if;

  insert into public.profiles (id, display_name, district, city)
    values (me, btrim(p_display_name), p_district, btrim(coalesce(p_city, '')))
    returning * into result;
  insert into public.profile_contacts (user_id, email, phone)
    values (me, lower(token_email), btrim(p_phone));
  return result;
end;
$$;

-- ---------------------------------------------------------------------------
-- Exchange workflow
-- ---------------------------------------------------------------------------

-- The donor picks one pending request for their item. Contact details are
-- shared between the two parties from this point (see profile_contacts).
create or replace function public.select_requester(p_request_id uuid)
returns public.exchanges
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := private.require_active_user();
  req public.item_requests%rowtype;
  itm public.items%rowtype;
  ex public.exchanges%rowtype;
begin
  select * into req from public.item_requests where id = p_request_id for update;
  if not found or req.item_id is null then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;

  select * into itm from public.items where id = req.item_id for update;
  if itm.donor_id <> me then
    raise exception 'Only the donor can select a requester' using errcode = '42501';
  end if;
  if itm.status <> 'active' or itm.is_hidden then
    raise exception 'This item is no longer available' using errcode = 'P0001';
  end if;
  if req.status <> 'pending' then
    raise exception 'This request is no longer pending' using errcode = 'P0001';
  end if;

  update public.item_requests set status = 'approved' where id = req.id;
  update public.items
    set status = 'pending_handover', selected_request_id = req.id
    where id = itm.id;
  insert into public.exchanges (item_id, request_id, item_title, donor_id, requester_id)
    values (itm.id, req.id, itm.title, itm.donor_id, req.requester_id)
    returning * into ex;
  return ex;
end;
$$;

-- Each party confirms the physical handover. The exchange (and item)
-- completes only when both have confirmed; confirming twice is a no-op.
create or replace function public.confirm_handover(p_item_id uuid)
returns public.exchanges
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := private.require_active_user();
  ex public.exchanges%rowtype;
begin
  select * into ex from public.exchanges
    where item_id = p_item_id and status = 'pending'
    for update;
  if not found then
    raise exception 'No handover in progress for this item' using errcode = 'P0002';
  end if;

  if me = ex.donor_id then
    update public.exchanges
      set donor_confirmed_at = coalesce(donor_confirmed_at, now())
      where id = ex.id returning * into ex;
  elsif me = ex.requester_id then
    update public.exchanges
      set requester_confirmed_at = coalesce(requester_confirmed_at, now())
      where id = ex.id returning * into ex;
  else
    raise exception 'You are not part of this exchange' using errcode = '42501';
  end if;

  if ex.donor_confirmed_at is not null and ex.requester_confirmed_at is not null then
    update public.exchanges
      set status = 'completed', completed_at = now()
      where id = ex.id returning * into ex;
    update public.items set status = 'completed' where id = ex.item_id;
    update public.profiles set donation_count = donation_count + 1 where id = ex.donor_id;
    -- Everyone else who asked for the item gets a definite answer.
    update public.item_requests set status = 'rejected'
      where item_id = ex.item_id and status = 'pending';
  end if;
  return ex;
end;
$$;

-- Either party backs out before completion: the item goes back on offer
-- and the selected request is declined.
create or replace function public.cancel_exchange(p_item_id uuid)
returns public.exchanges
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := private.require_active_user();
  ex public.exchanges%rowtype;
begin
  select * into ex from public.exchanges
    where item_id = p_item_id and status = 'pending'
    for update;
  if not found then
    raise exception 'No handover in progress for this item' using errcode = 'P0002';
  end if;
  if me <> ex.donor_id and me <> ex.requester_id then
    raise exception 'You are not part of this exchange' using errcode = '42501';
  end if;

  update public.exchanges
    set status = 'cancelled', cancelled_at = now(), cancelled_by = me
    where id = ex.id returning * into ex;
  update public.items
    set status = 'active', selected_request_id = null
    where id = ex.item_id;
  update public.item_requests set status = 'rejected' where id = ex.request_id;
  -- Ratings only stand for handovers that actually happened.
  delete from public.ratings where exchange_id = ex.id;
  return ex;
end;
$$;

-- Rate the other party once you have confirmed the handover. The ratee is
-- derived server-side, so a client cannot rate an arbitrary user.
create or replace function public.submit_rating(p_item_id uuid, p_stars integer, p_comment text default '')
returns public.ratings
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := private.require_active_user();
  ex public.exchanges%rowtype;
  ratee text;
  result public.ratings%rowtype;
begin
  select * into ex from public.exchanges
    where item_id = p_item_id and status <> 'cancelled'
    order by created_at desc
    limit 1;
  if not found then
    raise exception 'No handover found for this item' using errcode = 'P0002';
  end if;

  if me = ex.donor_id and ex.donor_confirmed_at is not null then
    ratee := ex.requester_id;
  elsif me = ex.requester_id and ex.requester_confirmed_at is not null then
    ratee := ex.donor_id;
  else
    raise exception 'Confirm the handover before rating' using errcode = '42501';
  end if;

  insert into public.ratings (exchange_id, item_id, rater_id, ratee_id, stars, comment)
    values (ex.id, ex.item_id, me, ratee, p_stars, btrim(coalesce(p_comment, '')))
    returning * into result;
  return result;
exception
  when unique_violation then
    raise exception 'You have already rated this exchange' using errcode = '23505';
end;
$$;

-- ---------------------------------------------------------------------------
-- Admin moderation
-- ---------------------------------------------------------------------------

create or replace function public.admin_set_user_status(p_user_id text, p_status public.account_status)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := private.require_admin();
  result public.profiles%rowtype;
begin
  if p_user_id = me then
    raise exception 'You cannot change your own account status' using errcode = 'P0001';
  end if;
  update public.profiles set status = p_status where id = p_user_id returning * into result;
  if not found then
    raise exception 'User not found' using errcode = 'P0002';
  end if;
  return result;
end;
$$;

-- Hiding is reversible, unlike deletion: the donor still sees the post.
create or replace function public.admin_set_item_hidden(p_item_id uuid, p_hidden boolean, p_reason text default null)
returns public.items
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := private.require_admin();
  result public.items%rowtype;
begin
  update public.items
    set is_hidden = p_hidden, hidden_reason = case when p_hidden then p_reason end
    where id = p_item_id returning * into result;
  if not found then
    raise exception 'Item not found' using errcode = 'P0002';
  end if;
  return result;
end;
$$;

create or replace function public.admin_set_request_hidden(p_request_id uuid, p_hidden boolean)
returns public.item_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := private.require_admin();
  result public.item_requests%rowtype;
begin
  update public.item_requests set is_hidden = p_hidden
    where id = p_request_id returning * into result;
  if not found then
    raise exception 'Request not found' using errcode = 'P0002';
  end if;
  return result;
end;
$$;

create or replace function public.admin_resolve_report(p_report_id uuid, p_status public.report_status, p_note text default null)
returns public.reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  me text := private.require_admin();
  result public.reports%rowtype;
begin
  if p_status = 'open' then
    raise exception 'Resolve a report as actioned or dismissed' using errcode = 'P0001';
  end if;
  update public.reports
    set status = p_status, resolved_by = me, resolved_at = now(), resolution_note = p_note
    where id = p_report_id returning * into result;
  if not found then
    raise exception 'Report not found' using errcode = 'P0002';
  end if;
  return result;
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: callable by signed-in clients (each function checks the caller)
-- ---------------------------------------------------------------------------

revoke all on function public.create_my_profile(text, text, text, text) from public;
revoke all on function public.select_requester(uuid) from public;
revoke all on function public.confirm_handover(uuid) from public;
revoke all on function public.cancel_exchange(uuid) from public;
revoke all on function public.submit_rating(uuid, integer, text) from public;
revoke all on function public.admin_set_user_status(text, public.account_status) from public;
revoke all on function public.admin_set_item_hidden(uuid, boolean, text) from public;
revoke all on function public.admin_set_request_hidden(uuid, boolean) from public;
revoke all on function public.admin_resolve_report(uuid, public.report_status, text) from public;

grant execute on function public.create_my_profile(text, text, text, text) to anon, authenticated;
grant execute on function public.select_requester(uuid) to anon, authenticated;
grant execute on function public.confirm_handover(uuid) to anon, authenticated;
grant execute on function public.cancel_exchange(uuid) to anon, authenticated;
grant execute on function public.submit_rating(uuid, integer, text) to anon, authenticated;
grant execute on function public.admin_set_user_status(text, public.account_status) to anon, authenticated;
grant execute on function public.admin_set_item_hidden(uuid, boolean, text) to anon, authenticated;
grant execute on function public.admin_set_request_hidden(uuid, boolean) to anon, authenticated;
grant execute on function public.admin_resolve_report(uuid, public.report_status, text) to anon, authenticated;
