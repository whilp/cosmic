-- type declarations for cosmo.lsqlite3

local record lsqlite3
  OK: number
  ERROR: number
  INTERNAL: number
  PERM: number
  ABORT: number
  BUSY: number
  LOCKED: number
  NOMEM: number
  READONLY: number
  INTERRUPT: number
  IOERR: number
  CORRUPT: number
  NOTFOUND: number
  FULL: number
  CANTOPEN: number
  PROTOCOL: number
  EMPTY: number
  SCHEMA: number
  TOOBIG: number
  CONSTRAINT: number
  MISMATCH: number
  MISUSE: number
  NOLFS: number
  FORMAT: number
  RANGE: number
  NOTADB: number
  ROW: number
  DONE: number
  CREATE_INDEX: number
  CREATE_TABLE: number
  CREATE_TEMP_INDEX: number
  CREATE_TEMP_TABLE: number
  CREATE_TEMP_TRIGGER: number
  CREATE_TEMP_VIEW: number
  CREATE_TRIGGER: number
  CREATE_VIEW: number
  DELETE: number
  DROP_INDEX: number
  DROP_TABLE: number
  DROP_TEMP_INDEX: number
  DROP_TEMP_TABLE: number
  DROP_TEMP_TRIGGER: number
  DROP_TEMP_VIEW: number
  DROP_TRIGGER: number
  DROP_VIEW: number
  INSERT: number
  PRAGMA: number
  READ: number
  SELECT: number
  TRANSACTION: number
  UPDATE: number
  ATTACH: number
  DETACH: number
  ALTER_TABLE: number
  REINDEX: number
  ANALYZE: number
  CREATE_VTABLE: number
  DROP_VTABLE: number
  FUNCTION: number
  SAVEPOINT: number
  OPEN_CREATE: number
  OPEN_PRIVATECACHE: number
  OPEN_FULLMUTEX: number
  OPEN_NOMUTEX: number
  OPEN_MEMORY: number
  OPEN_URI: number
  OPEN_READWRITE: number
  OPEN_READONLY: number
  OPEN_SHAREDCACHE: number
  TEXT: number
  BLOB: number
  NULL: number
  FLOAT: number

  --- Opens (or creates if it does not exist) an SQLite database with name filename
  --- and returns its handle as userdata (the returned object should be used for all
  --- further method calls in connection with this specific database, see Database
  --- methods). Example:
  --- myDB = lsqlite3.open('MyDatabase.sqlite3')  -- open
  --- -- do some database calls...
  --- myDB:close()  -- close
  --- In case of an error, the function returns `nil`, an error code and an error message.
  --- Since `0.9.4`, there is a second optional `flags` argument to `lsqlite3.open`.
  --- See https://www.sqlite.org/c3ref/open.html for an explanation of these flags and options.
  --- local db = lsqlite3.open('foo.db', lsqlite3.OPEN_READWRITE + lsqlite3.OPEN_CREATE + lsqlite3.OPEN_SHAREDCACHE)
  open: function(filename: string, flags?: number): Database
  --- Opens an SQLite database in memory and returns its handle as userdata. In case
  --- of an error, the function returns `nil`, an error code and an error message.
  --- (In-memory databases are volatile as they are never stored on disk.)
  open_memory: function(): Database
  lversion: function(): string
  version: function(): string
end

return lsqlite3

