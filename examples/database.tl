#!/usr/bin/env cosmic
--- SQLite database example using cosmo.lsqlite3.
---
--- Demonstrates:
--- - Opening/creating SQLite database
--- - Creating tables
--- - Inserting data with prepared statements
--- - Querying data
--- - Error handling
--- - Database cleanup
---
--- Usage:
---   ./cosmic-lua examples/database.tl
---
--- Creates example.db in the current directory.

local cosmic = require("cosmic")
local lsqlite3 = require("cosmo.lsqlite3")

cosmic.main(function(args: {string}, env: cosmic.Env): number, string
  local db_path = "example.db"

  env.stdout:write("Opening database: " .. db_path .. "\n")

  -- Open database (creates if doesn't exist)
  local db = lsqlite3.open(db_path)
  if not db then
    return 1, "Failed to open database: " .. db_path
  end

  -- Create table
  env.stdout:write("Creating table...\n")

  local create_sql = [[
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      created_at INTEGER DEFAULT (strftime('%s', 'now'))
    )
  ]]

  if db:exec(create_sql) ~= lsqlite3.OK then
    db:close()
    return 1, "Failed to create table: " .. db:errmsg()
  end

  -- Insert some sample data
  env.stdout:write("Inserting sample data...\n")

  local users = {
    {"Alice Anderson", "alice@example.com"},
    {"Bob Brown", "bob@example.com"},
    {"Carol Chen", "carol@example.com"},
  }

  local insert_stmt = db:prepare("INSERT OR IGNORE INTO users (name, email) VALUES (?, ?)")

  for _, user in ipairs(users) do
    insert_stmt:bind_values(user[1], user[2])

    local result = insert_stmt:step()

    if result == lsqlite3.DONE then
      env.stdout:write("  Inserted: " .. user[1] .. "\n")
    elseif result == lsqlite3.CONSTRAINT then
      env.stdout:write("  Skipped (duplicate): " .. user[1] .. "\n")
    else
      insert_stmt:finalize()
      db:close()
      return 1, "Insert failed: " .. db:errmsg()
    end

    insert_stmt:reset()
  end

  insert_stmt:finalize()

  -- Query and display all users
  env.stdout:write("\nAll users in database:\n")
  env.stdout:write(string.rep("-", 60) .. "\n")

  db:exec("SELECT id, name, email FROM users ORDER BY id", function(udata: any, cols: number, values: {string}, names: {string}): number
    env.stdout:write(string.format("  %s. %s <%s>\n", values[1], values[2], values[3]))
    return 0
  end)

  -- Get count
  local stmt = db:prepare("SELECT COUNT(*) FROM users")
  stmt:step()
  local count = stmt:get_value(1)
  stmt:finalize()

  env.stdout:write(string.rep("-", 60) .. "\n")
  env.stdout:write("Total users: " .. tostring(count) .. "\n")

  -- Clean up
  db:close()

  env.stdout:write("\nDatabase saved to: " .. db_path .. "\n")
  return 0
end)
