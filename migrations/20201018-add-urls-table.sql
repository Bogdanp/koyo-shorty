#lang north

-- @revision: f6f1178b45d5efa9a55a26c1a96a000e
-- @parent: efed79200bf19e497ce82c46ae7c7999
-- @description: Creates the "short_urls" table.
-- @up {
CREATE TABLE short_urls(
  id SERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  url TEXT NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- }

-- @down {
DROP TABLE short_urls;
-- }
