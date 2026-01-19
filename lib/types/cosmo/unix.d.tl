--- Low-level UNIX system call interface.
--- This module exposes the System V system call interface and works on all supported platforms,
--- including Windows NT where calls are emulated using native Windows APIs.

--- File metadata returned by stat().
local record Stat
  --- Get the file mode (permissions and type).
  --- @return number mode Unix file mode bits
  mode: function(self): number

  --- Get the file size in bytes.
  --- @return number size File size
  size: function(self): number

  --- Get the modification time.
  --- @return number mtime Modification time as Unix timestamp
  mtim: function(self): number
end

--- Directory handle for iterating through directory entries.
local record DirHandle
  --- Read the next directory entry.
  --- @return string|nil name Entry name, or nil when no more entries
  read: function(self): string

  --- Close the directory handle and release resources.
  close: function(self)

  --- Allow iteration: for entry in handle do
  metamethod __call: function(self: DirHandle): string
end

local record unix
  -- ============================================================================
  -- PROCESS CONTROL
  -- ============================================================================

  --- Create a new process by duplicating the current process.
  ---
  --- Returns 0 in the child process, and the child's PID in the parent process.
  --- This is useful for creating worker processes or handling concurrent requests.
  ---
  --- Example:
  ---
  ---     local unix = require("cosmo.unix")
  ---     local pid = unix.fork()
  ---     if pid == 0 then
  ---       -- Child process
  ---       print("I am the child")
  ---       unix.exit(0)
  ---     else
  ---       -- Parent process
  ---       print("Child PID:", pid)
  ---       unix.wait(pid)
  ---     end
  ---
  --- @return number pid 0 in child, child's PID in parent
  fork: function(): number

  --- Replace the current process with a new program.
  ---
  --- Executes the program at `path` with the given arguments and environment.
  --- This function never returns on success; it replaces the current process.
  --- `path` must be an absolute path to the executable.
  ---
  --- Example:
  ---
  ---     unix.execve("/bin/ls", {"/bin/ls", "-la", "."}, {"PATH=/bin"})
  ---     unix.exit(127)  -- Only reached if execve fails
  ---
  --- @param path string Absolute path to executable
  --- @param argv {string} Argument vector (argv[1] should be the program name)
  --- @param env {string} Environment variables as "KEY=value" strings
  execve: function(path: string, argv: {string}, env: {string})

  --- Execute program with PATH search.
  ---
  --- Like execve() but searches for the program in directories listed in
  --- the PATH environment variable. This function never returns on success.
  ---
  --- @param cmd string Program name or path
  --- @param argv {string} Argument vector
  execvp: function(cmd: string, argv: {string})

  --- Execute program with PATH search and custom environment.
  ---
  --- Combines execvp() and execve() - searches PATH and allows custom environment.
  --- This function never returns on success.
  ---
  --- @param cmd string Program name or path
  --- @param argv {string} Argument vector
  --- @param env {string} Environment variables as "KEY=value" strings
  execvpe: function(cmd: string, argv: {string}, env: {string})

  --- Wait for a child process to terminate.
  ---
  --- If pid is specified, waits for that specific child. Otherwise waits for
  --- any child process. Returns the PID of the terminated process and its
  --- exit status.
  ---
  --- Use WIFEXITED() and WEXITSTATUS() to interpret the status.
  ---
  --- @param pid number|nil Specific child PID, or nil for any child
  --- @return number pid PID of terminated child
  --- @return number status Exit status (use WIFEXITED/WEXITSTATUS to decode)
  wait: function(pid?: number): number, number

  --- Terminate the current process.
  ---
  --- @param code number Exit code (0 = success, non-zero = failure)
  exit: function(code: number)

  --- Send a signal to a process.
  ---
  --- @param pid number Process ID to signal
  --- @param signal number Signal number (e.g., SIGTERM, SIGINT)
  --- @return boolean success `true` on success
  kill: function(pid: number, signal: number): boolean

  --- Get the current process ID.
  ---
  --- @return number pid Current process ID
  getpid: function(): number

  --- Run the current process as a daemon (background service).
  ---
  --- Detaches from the controlling terminal and runs in the background.
  ---
  --- @param nochdir boolean If false, changes to root directory
  --- @param noclose boolean If false, redirects stdin/stdout/stderr to /dev/null
  --- @return boolean success `true` on success
  daemon: function(nochdir: boolean, noclose: boolean): boolean

  -- ============================================================================
  -- PIPES AND FILE DESCRIPTORS
  -- ============================================================================

  --- Create a pipe for inter-process communication.
  ---
  --- Returns two file descriptors: read end and write end.
  --- Data written to the write end can be read from the read end.
  ---
  --- Example:
  ---
  ---     local read_fd, write_fd = unix.pipe()
  ---     unix.write(write_fd, "Hello, pipe!")
  ---     local data = unix.read(read_fd, 100)
  ---     unix.close(read_fd)
  ---     unix.close(write_fd)
  ---
  --- @return number read_fd File descriptor for reading
  --- @return number write_fd File descriptor for writing
  pipe: function(): number, number

  --- Duplicate a file descriptor.
  ---
  --- If newfd is specified, duplicates oldfd to that specific number.
  --- Otherwise allocates the lowest available file descriptor.
  ---
  --- @param fd number File descriptor to duplicate
  --- @param newfd number|nil Target file descriptor number
  --- @return number fd New file descriptor
  dup: function(fd: number, newfd?: number): number

  -- ============================================================================
  -- FILE OPERATIONS
  -- ============================================================================

  --- Open a file and return a file descriptor.
  ---
  --- Flags should be a combination of O_RDONLY, O_WRONLY, O_RDWR, plus optional
  --- flags like O_CREAT, O_TRUNC, O_APPEND. Mode specifies permissions when
  --- creating a file (e.g., 0o644).
  ---
  --- Example:
  ---
  ---     local fd, err = unix.open("/tmp/test.txt",
  ---       unix.O_WRONLY + unix.O_CREAT + unix.O_TRUNC, 0o644)
  ---     if not fd then
  ---       print("Error:", err)
  ---       return
  ---     end
  ---     unix.write(fd, "Hello, World!")
  ---     unix.close(fd)
  ---
  --- @param path string Path to file
  --- @param flags number Open flags (O_RDONLY, O_WRONLY, O_RDWR, etc.)
  --- @param mode number|nil File permissions when creating (e.g., 0o644)
  --- @return number|nil fd File descriptor on success, nil on error
  --- @return string|nil error Error message on failure
  open: function(path: string, flags: number, mode?: number): number, string

  --- Close a file descriptor.
  ---
  --- @param fd number File descriptor to close
  --- @return boolean success `true` on success
  close: function(fd: number): boolean

  --- Read data from a file descriptor.
  ---
  --- Reads up to `size` bytes from the file descriptor.
  --- May return fewer bytes than requested.
  ---
  --- @param fd number File descriptor to read from
  --- @param size number Maximum number of bytes to read
  --- @return string data Data read from file descriptor
  read: function(fd: number, size: number): string

  --- Write data to a file descriptor.
  ---
  --- @param fd number File descriptor to write to
  --- @param data string Data to write
  --- @return number bytes Number of bytes written
  write: function(fd: number, data: string): number

  --- Reposition file offset.
  ---
  --- Changes the file offset for reading/writing.
  --- whence can be SEEK_SET (from start), SEEK_CUR (from current),
  --- or SEEK_END (from end).
  ---
  --- @param fd number File descriptor
  --- @param offset number Offset in bytes
  --- @param whence number SEEK_SET, SEEK_CUR, or SEEK_END
  --- @return number position New file offset
  lseek: function(fd: number, offset: number, whence: number): number

  --- Truncate a file to a specified length.
  ---
  --- @param fd number File descriptor
  --- @param length number New file length in bytes
  --- @return boolean success `true` on success
  ftruncate: function(fd: number, length: number): boolean

  -- ============================================================================
  -- DIRECTORY OPERATIONS
  -- ============================================================================

  --- Open a directory for reading its entries.
  ---
  --- Returns a handle that can be used to iterate through directory entries.
  ---
  --- Example:
  ---
  ---     local dir = unix.opendir("/tmp")
  ---     while true do
  ---       local entry = dir:read()
  ---       if not entry then break end
  ---       print(entry)
  ---     end
  ---     dir:close()
  ---
  --- @param path string Directory path
  --- @return DirHandle handle Directory handle
  opendir: function(path: string): DirHandle

  --- Create a directory.
  ---
  --- @param path string Directory path
  --- @param mode number Directory permissions (e.g., 0o755)
  --- @return boolean success `true` on success
  mkdir: function(path: string, mode: number): boolean

  --- Create a directory and all parent directories.
  ---
  --- Like `mkdir -p`, creates intermediate directories as needed.
  ---
  --- @param path string Directory path
  --- @param mode number|nil Directory permissions (defaults to 0o755)
  --- @return boolean success `true` on success
  --- @return string|nil error Error message on failure
  makedirs: function(path: string, mode?: number): boolean, string

  --- Create a temporary directory with a unique name.
  ---
  --- The template should end with "XXXXXX" which will be replaced with
  --- random characters to ensure uniqueness.
  ---
  --- Example:
  ---
  ---     local tmpdir = unix.mkdtemp("/tmp/myapp-XXXXXX")
  ---     -- Use tmpdir...
  ---     unix.rmrf(tmpdir)
  ---
  --- @param template string Path template ending in "XXXXXX"
  --- @return string path Created directory path
  mkdtemp: function(template: string): string

  --- Recursively remove a directory and all its contents.
  ---
  --- Like `rm -rf`, removes directories and files recursively.
  ---
  --- @param path string Directory path
  --- @return boolean success `true` on success
  rmrf: function(path: string): boolean

  --- Rename or move a file or directory.
  ---
  --- @param src string Source path
  --- @param dst string Destination path
  --- @return boolean success `true` on success
  rename: function(src: string, dst: string): boolean

  --- Remove a file or empty directory.
  ---
  --- @param path string File or directory path
  --- @return boolean success `true` on success
  unlink: function(path: string): boolean

  --- Create a symbolic link.
  ---
  --- @param target string Path the symlink points to
  --- @param link_path string Path where the symlink will be created
  --- @return boolean success `true` on success
  symlink: function(target: string, link_path: string): boolean

  --- Read the target of a symbolic link.
  ---
  --- @param path string Path to symbolic link
  --- @return string target Path the symlink points to
  readlink: function(path: string): string

  -- ============================================================================
  -- PATH AND DIRECTORY FUNCTIONS
  -- ============================================================================

  --- Get the current working directory.
  ---
  --- @return string cwd Current working directory path
  getcwd: function(): string

  --- Change the current working directory.
  ---
  --- @param path string New working directory path
  --- @return boolean success `true` on success
  chdir: function(path: string): boolean

  --- Resolve a path to its canonical absolute form.
  ---
  --- Resolves symbolic links and removes . and .. components.
  ---
  --- @param path string Path to resolve
  --- @return string realpath Canonical absolute path
  realpath: function(path: string): string

  --- Check file accessibility.
  ---
  --- Tests whether the file exists and has the requested permissions.
  --- Use F_OK to test existence, R_OK for read permission, W_OK for write,
  --- X_OK for execute.
  ---
  --- @param path string File path
  --- @param mode number Access mode (F_OK, R_OK, W_OK, X_OK)
  --- @return boolean accessible `true` if accessible
  access: function(path: string, mode: number): boolean

  --- Change file permissions.
  ---
  --- @param path string File path
  --- @param mode number New permissions (e.g., 0o644)
  --- @return boolean success `true` on success
  chmod: function(path: string, mode: number): boolean

  --- Get file metadata.
  ---
  --- Returns a Stat object with file information. Use flags to control
  --- behavior (e.g., AT_SYMLINK_NOFOLLOW to not follow symlinks).
  ---
  --- @param path string File path
  --- @param flags number|nil Stat flags (e.g., AT_SYMLINK_NOFOLLOW)
  --- @return Stat stat File metadata
  stat: function(path: string, flags?: number): Stat

  -- ============================================================================
  -- ENVIRONMENT
  -- ============================================================================

  --- Get all environment variables.
  ---
  --- Returns an array of "KEY=value" strings.
  ---
  --- @return {string} env Environment variables
  environ: function(): {string}

  --- Set an environment variable.
  ---
  --- @param name string Variable name
  --- @param value string Variable value
  --- @return boolean success `true` on success
  setenv: function(name: string, value: string): boolean

  --- Unset an environment variable.
  ---
  --- @param name string Variable name
  --- @return boolean success `true` on success
  unsetenv: function(name: string): boolean

  --- Search for a command in PATH.
  ---
  --- Returns the full path to the command if found in PATH.
  ---
  --- Example:
  ---
  ---     local ls = unix.commandv("ls")
  ---     if ls then
  ---       unix.execve(ls, {ls, "-la"}, unix.environ())
  ---     end
  ---
  --- @param cmd string Command name
  --- @return string path Full path to command
  commandv: function(cmd: string): string

  --- Get the system hostname.
  ---
  --- @return string hostname System hostname
  gethostname: function(): string

  -- ============================================================================
  -- TIME
  -- ============================================================================

  --- Sleep for a specified time.
  ---
  --- @param sec number Seconds to sleep
  --- @param nsec number Nanoseconds to sleep
  nanosleep: function(sec: number, nsec: number)

  -- ============================================================================
  -- NETWORK
  -- ============================================================================

  --- Create a network socket.
  ---
  --- @param family number Address family (e.g., AF_UNIX)
  --- @param socktype number Socket type (e.g., SOCK_STREAM)
  --- @return number fd Socket file descriptor
  socket: function(family: number, socktype: number): number

  --- Connect a socket to an address.
  ---
  --- For AF_UNIX sockets, path is the socket file path.
  ---
  --- @param fd number Socket file descriptor
  --- @param path string Address (e.g., socket path for AF_UNIX)
  --- @return boolean success `true` on success
  connect: function(fd: number, path: string): boolean

  -- ============================================================================
  -- SIGNALS
  -- ============================================================================

  --- Install a signal handler.
  ---
  --- @param signal number Signal number (e.g., SIGINT, SIGTERM)
  --- @param handler function Handler function to call when signal is received
  sigaction: function(signal: number, handler: function())

  -- ============================================================================
  -- FILE LOCKING
  -- ============================================================================

  --- Manipulate file descriptor (including file locking).
  ---
  --- Used for advisory file locking. Set lock_type to F_WRLCK for write lock.
  ---
  --- @param fd number File descriptor
  --- @param cmd number Command (e.g., F_SETLK)
  --- @param lock_type number Lock type (e.g., F_WRLCK)
  --- @param whence number|nil Lock start reference (SEEK_SET, SEEK_CUR, SEEK_END)
  --- @param start number|nil Lock start offset
  --- @param len number|nil Lock length (0 = to EOF)
  --- @return number result Result code
  fcntl: function(fd: number, cmd: number, lock_type: number, whence?: number, start?: number, len?: number): number

  -- ============================================================================
  -- CONSTANTS
  -- ============================================================================

  -- File flags
  O_RDONLY: number    --- Open for reading only
  O_WRONLY: number    --- Open for writing only
  O_RDWR: number      --- Open for reading and writing
  O_CREAT: number     --- Create file if it doesn't exist
  O_EXCL: number      --- Fail if file exists (with O_CREAT)
  O_TRUNC: number     --- Truncate file to 0 bytes
  O_APPEND: number    --- Append mode

  -- File type tests
  --- Test if mode indicates a directory.
  S_ISDIR: function(mode: number): boolean

  --- Test if mode indicates a regular file.
  S_ISREG: function(mode: number): boolean

  --- Test if mode indicates a symbolic link.
  S_ISLNK: function(mode: number): boolean

  -- Process status
  --- Test if child exited normally.
  WIFEXITED: function(status: number): boolean

  --- Extract exit status if WIFEXITED is true.
  WEXITSTATUS: function(status: number): number

  -- Access modes
  F_OK: number        --- Test for file existence
  X_OK: number        --- Test for execute permission
  R_OK: number        --- Test for read permission
  W_OK: number        --- Test for write permission

  -- Lock modes
  F_SETLK: number     --- Set lock (non-blocking)
  F_WRLCK: number     --- Write lock

  -- Signals
  SIGINT: integer     --- Interrupt signal (Ctrl+C)
  SIGTERM: integer    --- Termination signal

  -- Network constants
  AF_UNIX: number     --- Unix domain sockets
  SOCK_STREAM: number --- Stream socket (TCP)

  -- Stat flags
  AT_SYMLINK_NOFOLLOW: number  --- Don't follow symbolic links

  -- Seek whence
  SEEK_SET: number    --- Seek from beginning of file
  SEEK_CUR: number    --- Seek from current position
  SEEK_END: number    --- Seek from end of file
end

return unix
