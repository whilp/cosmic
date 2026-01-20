# maxmind

Type declarations for the `maxmind` module.

## Types

### Db

```teal
local record Db
  lookup: function(self: Db, ip: number): Result
end
```

### Result

```teal
local record Result
  get: function(self: Result): any
  netmask: function(self: Result): number
end
```

## Functions

### open

```teal
function open(filepath: string): Db
```

**Parameters:**

- `filepath` (string)

**Returns:**

- Db
