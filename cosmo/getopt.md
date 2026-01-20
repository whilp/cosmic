# getopt

Type declarations for the `getopt` module.

## Types

### parser

```teal
local record parser
  next: function(self: parser): string, string
  remaining: function(self: parser): {string}
  unknown: function(self: parser): {string}
end
```

## Functions

### new

```teal
function new(args: {string}, optstring: string, longopts?: {table}): parser
```

**Parameters:**

- `args` ({string})
- `optstring` (string)
- `longopts` ({table})

**Returns:**

- parser
