-- docs-publish: publish generated docs to a git branch
local cosmo = require("cosmo")
local path = require("cosmo.path")
local unix = require("cosmo.unix")
local spawn = require("cosmic.spawn")

local record DirHandle
  read: function(DirHandle): string
  close: function(DirHandle)
end

local function run(argv: {string}): boolean, string
  local h, err = spawn(argv)
  if not h then
    return nil, err
  end
  local code = h:wait()
  if code ~= 0 then
    return nil, table.concat(argv, " ") .. " failed with exit code " .. code
  end
  return true
end

local function run_output(argv: {string}): string
  local h = spawn(argv)
  if not h then return nil end
  local ok, out = h:read()
  if ok then return out end
  return nil
end

local function copy_recursive(src: string, dst: string): boolean, string
  local stat = unix.stat(src)
  if not stat then
    return nil, "source not found: " .. src
  end

  if unix.S_ISDIR(stat:mode()) then
    unix.makedirs(dst)
    local dir = unix.opendir(src) as DirHandle
    if not dir then
      return nil, "failed to open " .. src
    end
    while true do
      local name = dir:read()
      if not name then break end
      if name ~= "." and name ~= ".." then
        local ok, err = copy_recursive(path.join(src, name), path.join(dst, name))
        if not ok then return nil, err end
      end
    end
  else
    local f = io.open(src, "rb")
    if not f then return nil, "failed to open " .. src end
    local content = f:read("*a")
    f:close()
    unix.makedirs(path.dirname(dst))
    local out = io.open(dst, "wb")
    if not out then return nil, "failed to create " .. dst end
    out:write(content)
    out:close()
  end
  return true
end

local function main(source_sha: string, docs_dir: string, branch: string): boolean, string
  if not source_sha or not docs_dir or not branch then
    return nil, "usage: docs-publish <source_sha> <docs_dir> <branch>"
  end

  -- configure git
  local ok, err = run({"git", "config", "user.name", "github-actions[bot]"})
  if not ok then return nil, err end
  ok, err = run({"git", "config", "user.email", "github-actions[bot]@users.noreply.github.com"})
  if not ok then return nil, err end

  -- fetch and checkout docs branch, or create orphan
  local fetch_h = spawn({"git", "fetch", "origin", branch})
  local fetch_ok = fetch_h and fetch_h:wait() == 0

  if fetch_ok then
    ok, err = run({"git", "checkout", branch})
    if not ok then return nil, err end
  else
    io.stderr:write("creating new orphan " .. branch .. " branch\n")
    ok, err = run({"git", "checkout", "--orphan", branch})
    if not ok then return nil, err end
  end

  -- remove old content (ignore errors for empty repos)
  spawn({"git", "rm", "-rf", "."}):wait()

  -- clear working directory
  local dir = unix.opendir(".") as DirHandle
  if dir then
    while true do
      local name = dir:read()
      if not name then break end
      if name ~= "." and name ~= ".." and name ~= ".git" then
        unix.rmrf(name)
      end
    end
  end

  -- copy docs
  ok, err = copy_recursive(docs_dir, ".")
  if not ok then return nil, err end

  -- write readme
  local readme = io.open("README.md", "w")
  if readme then
    readme:write([[# Generated Documentation

This branch contains auto-generated documentation from the cosmic-lua source code.

## Contents

Documentation is generated from Teal source files using `cosmic --doc`.

To regenerate locally:
```bash
make doc
```

---
*This branch is automatically updated by GitHub Actions. Do not edit manually.*
]])
    readme:close()
  end

  -- stage all changes
  ok, err = run({"git", "add", "-A"})
  if not ok then return nil, err end

  -- check if there are changes
  local diff_h = spawn({"git", "diff", "--staged", "--quiet"})
  if diff_h and diff_h:wait() == 0 then
    io.stderr:write("no documentation changes detected\n")
    return true
  end

  -- commit and push
  ok, err = run({"git", "commit", "-m", "docs: update from " .. source_sha})
  if not ok then return nil, err end

  ok, err = run({"git", "push", "--force-with-lease", "-u", "origin", branch})
  if not ok then return nil, err end

  io.stderr:write("published docs from " .. source_sha .. " to " .. branch .. "\n")
  return true
end

if cosmo.is_main() then
  local ok, err = main(arg[1], arg[2], arg[3])
  if not ok then
    io.stderr:write("error: " .. tostring(err) .. "\n")
    os.exit(1)
  end
end
