--- SQLite database access.
--- The lsqlite3 module provides a Lua binding to SQLite, allowing you to create,
--- query, and manipulate SQLite databases.

--- Prepared SQL statement for executing queries with parameters.
local record Statement
  --- Bind values to placeholders in the prepared statement.
  ---
  --- Binds values to ? placeholders in the SQL statement, in order.
  ---
  --- Example:
  ---
  ---     local stmt = db:prepare("INSERT INTO users (name, age) VALUES (?, ?)")
  ---     stmt:bind_values("Alice", 30)
  ---     stmt:step()
  ---
  --- @param ... any Values to bind to the statement placeholders
  bind_values: function(self: Statement, ...: any)

  --- Execute one step of the prepared statement.
  ---
  --- Returns a status code:
  --- - 100 (SQLITE_ROW): A row is available, call step() again to get more rows
  --- - 101 (SQLITE_DONE): Statement completed successfully
  --- - Other: Error occurred
  ---
  --- @return number status SQLite status code
  step: function(self: Statement): number

  --- Return an iterator for rows returned by the statement.
  ---
  --- Each call to the iterator returns a table mapping column names to values.
  --- Returns nil when no more rows are available.
  ---
  --- Example:
  ---
  ---     local stmt = db:prepare("SELECT name, age FROM users")
  ---     for row in stmt:nrows() do
  ---       print(row.name, row.age)
  ---     end
  ---
  --- @return function iterator Iterator function that returns row tables
  nrows: function(self: Statement): function(): {string:any}

  --- Finalize and release the prepared statement.
  ---
  --- This should be called when you're done with the statement to free resources.
  finalize: function(self: Statement)

  --- Reset the statement to be executed again with new bindings.
  ---
  --- After reset, you can bind new values and execute the statement again.
  reset: function(self: Statement)
end

--- SQLite database connection.
local record Database
  --- Execute an SQL statement without returning results.
  ---
  --- Suitable for CREATE, INSERT, UPDATE, DELETE statements.
  ---
  --- Example:
  ---
  ---     db:exec("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
  ---     db:exec("INSERT INTO users (name, age) VALUES ('Alice', 30)")
  ---
  --- @param sql string SQL statement to execute
  --- @return number status SQLite status code (0 = success)
  exec: function(self: Database, sql: string): number

  --- Prepare an SQL statement for execution.
  ---
  --- Returns a Statement object that can be executed multiple times with
  --- different bound parameters.
  ---
  --- @param sql string SQL statement to prepare
  --- @return Statement stmt Prepared statement object
  prepare: function(self: Database, sql: string): Statement

  --- Execute a query and return an iterator for the results.
  ---
  --- Convenience method that combines prepare() and nrows().
  ---
  --- Example:
  ---
  ---     for row in db:nrows("SELECT name, age FROM users WHERE age > 25") do
  ---       print(row.name, row.age)
  ---     end
  ---
  --- @param sql string SQL query to execute
  --- @return function iterator Iterator function that returns row tables
  nrows: function(self: Database, sql: string): function(): {string:any}

  --- Close the database connection and release resources.
  close: function(self: Database)
end

local record lsqlite3
  --- Open or create an SQLite database.
  ---
  --- Opens an existing database or creates a new one if it doesn't exist.
  --- Use ":memory:" as the filename to create an in-memory database.
  ---
  --- Example - File database:
  ---
  ---     local lsqlite3 = require("cosmo.lsqlite3")
  ---     local db = assert(lsqlite3.open("mydata.db"))
  ---     db:exec("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)")
  ---     db:exec("INSERT INTO users (name) VALUES ('Alice')")
  ---     for row in db:nrows("SELECT * FROM users") do
  ---       print(row.id, row.name)
  ---     end
  ---     db:close()
  ---
  --- Example - In-memory database:
  ---
  ---     local db = lsqlite3.open(":memory:")
  ---     db:exec("CREATE TABLE temp (data TEXT)")
  ---
  --- @param filename string Path to database file, or ":memory:" for in-memory database
  --- @return Database db Database connection object
  open: function(filename: string): Database
end

return lsqlite3
