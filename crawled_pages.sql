-- Enable the pgvector extension
create extension if not exists vector;

-- Drop tables if they exist (to allow rerunning the script)
drop table if exists {{PREFIX}}crawled_pages;
drop table if exists {{PREFIX}}code_examples;
drop table if exists {{PREFIX}}sources;

-- Create the sources table
create table {{PREFIX}}sources (
    source_id text primary key,
    summary text,
    total_word_count integer default 0,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create the documentation chunks table
create table {{PREFIX}}crawled_pages (
    id bigserial primary key,
    url varchar not null,
    chunk_number integer not null,
    content text not null,
    metadata jsonb not null default '{}'::jsonb,
    source_id text not null,
    embedding vector(1536),  -- OpenAI embeddings are 1536 dimensions
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    
    -- Add a unique constraint to prevent duplicate chunks for the same URL
    unique(url, chunk_number),
    
    -- Add foreign key constraint to sources table
    foreign key (source_id) references {{PREFIX}}sources(source_id)
);

-- Create an index for better vector similarity search performance
create index on {{PREFIX}}crawled_pages using ivfflat (embedding vector_cosine_ops);

-- Create an index on metadata for faster filtering
create index idx_{{PREFIX}}crawled_pages_metadata on {{PREFIX}}crawled_pages using gin (metadata);

-- Create an index on source_id for faster filtering
CREATE INDEX idx_{{PREFIX}}crawled_pages_source_id ON {{PREFIX}}crawled_pages (source_id);

-- Create a function to search for documentation chunks
create or replace function match_{{PREFIX}}crawled_pages (
  query_embedding vector(1536),
  match_count int default 10,
  filter jsonb DEFAULT '{}'::jsonb,
  source_filter text DEFAULT NULL
) returns table (
  id bigint,
  url varchar,
  chunk_number integer,
  content text,
  metadata jsonb,
  source_id text,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    url,
    chunk_number,
    content,
    metadata,
    source_id,
    1 - ({{PREFIX}}crawled_pages.embedding <=> query_embedding) as similarity
  from {{PREFIX}}crawled_pages
  where metadata @> filter
    AND (source_filter IS NULL OR source_id = source_filter)
  order by {{PREFIX}}crawled_pages.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- Enable RLS on the crawled_pages table
alter table {{PREFIX}}crawled_pages enable row level security;

-- Create a policy that allows anyone to read crawled_pages
create policy "Allow public read access to {{PREFIX}}crawled_pages"
  on {{PREFIX}}crawled_pages
  for select
  to public
  using (true);

-- Enable RLS on the sources table
alter table {{PREFIX}}sources enable row level security;

-- Create a policy that allows anyone to read sources
create policy "Allow public read access to {{PREFIX}}sources"
  on {{PREFIX}}sources
  for select
  to public
  using (true);

-- Create the code_examples table
create table {{PREFIX}}code_examples (
    id bigserial primary key,
    url varchar not null,
    chunk_number integer not null,
    content text not null,  -- The code example content
    summary text not null,  -- Summary of the code example
    metadata jsonb not null default '{}'::jsonb,
    source_id text not null,
    embedding vector(1536),  -- OpenAI embeddings are 1536 dimensions
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    
    -- Add a unique constraint to prevent duplicate chunks for the same URL
    unique(url, chunk_number),
    
    -- Add foreign key constraint to sources table
    foreign key (source_id) references {{PREFIX}}sources(source_id)
);

-- Create an index for better vector similarity search performance
create index on {{PREFIX}}code_examples using ivfflat (embedding vector_cosine_ops);

-- Create an index on metadata for faster filtering
create index idx_{{PREFIX}}code_examples_metadata on {{PREFIX}}code_examples using gin (metadata);

-- Create an index on source_id for faster filtering
CREATE INDEX idx_{{PREFIX}}code_examples_source_id ON {{PREFIX}}code_examples (source_id);

-- Create a function to search for code examples
create or replace function match_{{PREFIX}}code_examples (
  query_embedding vector(1536),
  match_count int default 10,
  filter jsonb DEFAULT '{}'::jsonb,
  source_filter text DEFAULT NULL
) returns table (
  id bigint,
  url varchar,
  chunk_number integer,
  content text,
  summary text,
  metadata jsonb,
  source_id text,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    url,
    chunk_number,
    content,
    summary,
    metadata,
    source_id,
    1 - ({{PREFIX}}code_examples.embedding <=> query_embedding) as similarity
  from {{PREFIX}}code_examples
  where metadata @> filter
    AND (source_filter IS NULL OR source_id = source_filter)
  order by {{PREFIX}}code_examples.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- Enable RLS on the code_examples table
alter table {{PREFIX}}code_examples enable row level security;

-- Create a policy that allows anyone to read code_examples
create policy "Allow public read access to {{PREFIX}}code_examples"
  on {{PREFIX}}code_examples
  for select
  to public
  using (true);