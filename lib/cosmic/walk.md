# walk

 Directory tree walking utilities.
 Recursively traverse directories with visitor pattern or glob matching.

## Types

### Stat

 File or directory metadata.

```teal
local record Stat
  mode: function(self): number
  size: function(self): number
  mtim: function(self): number
end
```

### DirHandle

 Handle for reading directory entries.

```teal
local record DirHandle
  read: function(self): string
  close: function(self)
end
```

### FileInfo

 File information with Unix permissions.

```teal
local record FileInfo
  mode: number
end
```
