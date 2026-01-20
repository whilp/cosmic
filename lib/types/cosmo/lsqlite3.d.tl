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

  open: function(filename: string, flags?: number): Database
  open_memory: function(): Database
  lversion: function(): string
  version: function(): string
end

return lsqlite3

