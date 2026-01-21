--- Embed files into cosmic executable.
--- Creates a copy of the cosmic executable with files appended as a zip archive.

local cosmo = require("cosmo")
local zip = require("cosmo.zip")

--- Result returned from embed operation.
local record EmbedResult
  ok: boolean
  message: string
  file_count: integer
end

--- Appender interface for adding files to a ZIP archive.
local record ZipAppender
  add: function(self: ZipAppender, name: string, content: string): boolean, string
  close: function(self: ZipAppender)
end

--- Embed files into a copy of the cosmic executable.
--- Creates a new executable with files appended as a zip archive.
--- The original executable is copied and files are added to the end as a zip.
--- @param files {string} List of file paths to embed
--- @param output string Output path for the new executable (defaults to "cosmic")
--- @param exe_path string Path to the executable to copy (defaults to arg[-1])
--- @return EmbedResult Result with ok status, message, and file count
local function run(files: {string}, output?: string, exe_path?: string): EmbedResult
  output = output or "cosmic"
  exe_path = exe_path or arg[-1]

  if not exe_path then
    return {ok = false, message = "error: could not determine executable path", file_count = 0}
  end

  if #files == 0 then
    return {ok = false, message = "error: no files specified", file_count = 0}
  end

  -- Read all input files first to fail fast on errors
  local record FileToEmbed
    path: string
    content: string
    stored_name: string
  end
  local files_to_embed: {FileToEmbed} = {}

  for _, file in ipairs(files) do
    local f, open_err = io.open(file, "rb")
    if not f then
      return {ok = false, message = "error: cannot open file '" .. file .. "': " .. (open_err or "unknown error"), file_count = 0}
    end
    local content = f:read("*a")
    f:close()

    -- Strip leading / for absolute paths to make them relative in zip
    local stored_name = file:gsub("^/+", "")

    files_to_embed[#files_to_embed + 1] = {
      path = file,
      content = content,
      stored_name = stored_name,
    }
  end

  -- Copy the executable to output
  local exe_data = cosmo.Slurp(exe_path)
  if not exe_data then
    return {ok = false, message = "error: cannot read executable '" .. exe_path .. "'", file_count = 0}
  end
  if not cosmo.Barf(output, exe_data, tonumber("755", 8)) then
    return {ok = false, message = "error: cannot write to '" .. output .. "'", file_count = 0}
  end

  -- Open output as zip for appending
  -- Note: Using temporary variable to work around Teal's union type handling
  local zip_result: any
  local zip_err: any
  zip_result, zip_err = zip.open(output, "a")
  if not zip_result then
    return {ok = false, message = "error: failed to open zip for appending: " .. tostring(zip_err or "unknown error"), file_count = 0}
  end

  -- Cast to ZipAppender since we know mode "a" returns an Appender
  local appender = zip_result as ZipAppender

  -- Add each file to the zip
  for _, file_info in ipairs(files_to_embed) do
    local add_ok, add_err = appender:add(file_info.stored_name, file_info.content)
    if not add_ok then
      appender:close()
      return {ok = false, message = "error: failed to add '" .. file_info.path .. "' to zip: " .. tostring(add_err or "unknown error"), file_count = 0}
    end
  end

  appender:close()

  return {
    ok = true,
    message = "Successfully embedded " .. #files .. " file(s) into " .. output,
    file_count = #files,
  }
end

local record EmbedModule
  run: function(files: {string}, output?: string, exe_path?: string): EmbedResult
end

local M: EmbedModule = {
  run = run,
}

return M
