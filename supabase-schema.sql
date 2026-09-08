create extension if not exists "pgcrypto";


/* ================= PROFILES ================= */

create table if not exists public.profiles (

  id uuid primary key
    references auth.users(id)
    on delete cascade,

  full_name text not null default '',

  username text unique,

  bio text default '',

  avatar_url text,

  cover_url text,

  created_at timestamptz
    not null default now(),

  updated_at timestamptz
    not null default now()
);


/* ================= POSTS ================= */

create table if not exists public.posts (

  id uuid primary key
    default gen_random_uuid(),

  user_id uuid
    not null references public.profiles(id)
    on delete cascade,

  content text,

  media_url text,

  media_type text,

  created_at timestamptz
    not null default now()
);


/* ================= COMMENTS ================= */

create table if not exists public.comments (

  id uuid primary key
    default gen_random_uuid(),

  post_id uuid
    not null references public.posts(id)
    on delete cascade,

  user_id uuid
    not null references public.profiles(id)
    on delete cascade,

  content text
    not null,

  created_at timestamptz
    not null default now()
);


/* ================= LIKES ================= */

create table if not exists public.post_likes (

  post_id uuid
    not null references public.posts(id)
    on delete cascade,

  user_id uuid
    not null references public.profiles(id)
    on delete cascade,

  created_at timestamptz
    not null default now(),

  primary key(post_id,user_id)
);


/* ================= FOLLOWS ================= */

create table if not exists public.follows (

  follower_id uuid
    not null references public.profiles(id)
    on delete cascade,

  following_id uuid
    not null references public.profiles(id)
    on delete cascade,

  created_at timestamptz
    not null default now(),

  primary key(
    follower_id,
    following_id
  ),

  check(follower_id <> following_id)
);


/* ================= NOTIFICATIONS ================= */

create table if not exists public.notifications (

  id uuid primary key
    default gen_random_uuid(),

  user_id uuid
    not null references auth.users(id)
    on delete cascade,

  actor_id uuid
    not null references auth.users(id)
    on delete cascade,

  type text
    not null,

  post_id uuid
    references public.posts(id)
    on delete cascade,

  is_read boolean
    not null default false,

  created_at timestamptz
    not null default now()
);


/* ================= INDEXES ================= */

create index if not exists posts_user_id_idx
on public.posts(user_id);

create index if not exists posts_created_at_idx
on public.posts(created_at desc);

create index if not exists comments_post_id_idx
on public.comments(post_id);

create index if not exists follows_following_idx
on public.follows(following_id);

create index if not exists follows_follower_idx
on public.follows(follower_id);

create index if not exists notifications_user_id_idx
on public.notifications(user_id);


/* ================= PROFILE TRIGGER ================= */

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$

begin

  insert into public.profiles(
    id,
    full_name,
    username
  )

  values(
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      ''
    ),
    nullif(
      new.raw_user_meta_data->>'username',
      ''
    )
  )

  on conflict(id) do nothing;

  return new;

end;

$$;


drop trigger if exists on_auth_user_created
on auth.users;


create trigger on_auth_user_created

after insert on auth.users

for each row

execute procedure public.handle_new_user();


/* ================= RLS ================= */

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.post_likes enable row level security;
alter table public.follows enable row level security;
alter table public.notifications enable row level security;


/* PROFILES */

drop policy if exists "profiles_select"
on public.profiles;

create policy "profiles_select"

on public.profiles

for select

using(true);


drop policy if exists "profiles_insert"
on public.profiles;

create policy "profiles_insert"

on public.profiles

for insert

with check(auth.uid() = id);


drop policy if exists "profiles_update"
on public.profiles;

create policy "profiles_update"

on public.profiles

for update

using(auth.uid() = id)

with check(auth.uid() = id);


/* POSTS */

drop policy if exists "posts_select"
on public.posts;

create policy "posts_select"

on public.posts

for select

using(true);


drop policy if exists "posts_insert"
on public.posts;

create policy "posts_insert"

on public.posts

for insert

with check(auth.uid() = user_id);


drop policy if exists "posts_delete"
on public.posts;

create policy "posts_delete"

on public.posts

for delete

using(auth.uid() = user_id);


/* COMMENTS */

drop policy if exists "comments_select"
on public.comments;

create policy "comments_select"

on public.comments

for select

using(true);


drop policy if exists "comments_insert"
on public.comments;

create policy "comments_insert"

on public.comments

for insert

with check(auth.uid() = user_id);


drop policy if exists "comments_delete"
on public.comments;

create policy "comments_delete"

on public.comments

for delete

using(auth.uid() = user_id);


/* LIKES */

drop policy if exists "likes_select"
on public.post_likes;

create policy "likes_select"

on public.post_likes

for select

using(true);


drop policy if exists "likes_insert"
on public.post_likes;

create policy "likes_insert"

on public.post_likes

for insert

with check(auth.uid() = user_id);


drop policy if exists "likes_delete"
on public.post_likes;

create policy "likes_delete"

on public.post_likes

for delete

using(auth.uid() = user_id);


/* FOLLOWS */

drop policy if exists "follows_select"
on public.follows;

create policy "follows_select"

on public.follows

for select

using(true);


drop policy if exists "follows_insert"
on public.follows;

create policy "follows_insert"

on public.follows

for insert

with check(auth.uid() = follower_id);


drop policy if exists "follows_delete"
on public.follows;

create policy "follows_delete"

on public.follows

for delete

using(auth.uid() = follower_id);


/* NOTIFICATIONS */

drop policy if exists "notifications_select"
on public.notifications;

create policy "notifications_select"

on public.notifications

for select

using(auth.uid() = user_id);


drop policy if exists "notifications_insert"
on public.notifications;

create policy "notifications_insert"

on public.notifications

for insert

with check(auth.uid() = actor_id);


drop policy if exists "notifications_update"
on public.notifications;

create policy "notifications_update"

on public.notifications

for update

using(auth.uid() = user_id);


/* ================= STORAGE ================= */

insert into storage.buckets(
  id,
  name,
  public
)

values(
  'media',
  'media',
  true
)

on conflict(id) do update
set public = true;


/* STORAGE READ */

drop policy if exists "media_public_read"
on storage.objects;

create policy "media_public_read"

on storage.objects

for select

using(
  bucket_id = 'media'
);


/* STORAGE UPLOAD */

drop policy if exists "media_authenticated_upload"
on storage.objects;

create policy "media_authenticated_upload"

on storage.objects

for insert

to authenticated

with check(
  bucket_id = 'media'
);


/* STORAGE DELETE */

drop policy if exists "media_owner_delete"
on storage.objects;

create policy "media_owner_delete"

on storage.objects

for delete

to authenticated

using(
  bucket_id = 'media'
  and owner_id = auth.uid()::text
);
