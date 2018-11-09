-- http://postgrest.org/en/v5.1/tutorials/tut0.html#step-4-create-database-for-api

-- create a named schema for the database objects which will be exposed in the API.
create schema public;

-- API will have one endpoint, /todos, which will come from a table.
create table public.todos (
  id serial primary key,
  done boolean not null default false,
  task text not null,
  due timestamptz
);

insert into public.todos (task) values
  ('finish tutorial 0'), ('pat self on back');

-- make a role to use for anonymous web requests.
create role web_anon nologin;
grant web_anon to postgres;

grant usage on schema public to web_anon;
-- grant select on public.todos to web_anon;

-- make a role called notes_user for users who authenticate with the API.
-- This role will have the authority to do anything to the todo list.

create role notes_user nologin;
grant notes_user to postgres;

grant usage on schema public to notes_user;
grant all on public.todos to notes_user;
grant usage, select on sequence public.todos_id_seq to notes_user;
