--- System calls and POSIX bindings.
--- Low-level Unix system call interface with comprehensive POSIX support.

--- Shared memory for inter-process communication.
--- Provides atomic operations and wait/wake primitives for synchronization.
local record Memory
  read: function(self: Memory, offset?: number, bytes?: number): string
  write: function(self: Memory, data: string, offset?: number, bytes?: number)
  load: function(self: Memory, word_index: number): number
  store: function(self: Memory, word_index: number, value: number)
  xchg: function(self: Memory, word_index: number, value: number): number
  cmpxchg: function(self: Memory, word_index: number, old: number, new: number): boolean
  fetch_add: function(self: Memory, word_index: number, value: number): number
  fetch_and: function(self: Memory, word_index: number, value: number): number
  fetch_or: function(self: Memory, word_index: number, value: number): number
  fetch_xor: function(self: Memory, word_index: number, value: number): number
  wait: function(self: Memory, word_index: number, expect: number, abs_deadline?: number, nanos?: number): number
  wake: function(self: Memory, index: number, count?: number): number
end

--- Directory handle for reading directory entries.
--- Created by `opendir()` or `fdopendir()`.
local record Dir
  --- Close the directory handle and release resources.
  close: function(self: Dir): boolean

  --- Read the next directory entry.
  --- Returns the filename, or nil when no more entries.
  read: function(self: Dir): string

  --- Get the underlying file descriptor.
  fd: function(self: Dir): number

  --- Get the current position in the directory stream.
  tell: function(self: Dir): number

  --- Reset the directory stream to the beginning.
  rewind: function(self: Dir)
end

--- Resource usage statistics for a process.
--- Contains CPU time, memory usage, I/O, and context switch counters.
local record Rusage
  utime: function(self: Rusage): number
  stime: function(self: Rusage): number
  maxrss: function(self: Rusage): number
  idrss: function(self: Rusage): number
  ixrss: function(self: Rusage): number
  isrss: function(self: Rusage): number
  minflt: function(self: Rusage): number
  majflt: function(self: Rusage): number
  nswap: function(self: Rusage): number
  inblock: function(self: Rusage): number
  oublock: function(self: Rusage): number
  msgsnd: function(self: Rusage): number
  msgrcv: function(self: Rusage): number
  nsignals: function(self: Rusage): number
  nvcsw: function(self: Rusage): number
  nivcsw: function(self: Rusage)
end

--- File metadata and attributes.
--- Contains file size, permissions, ownership, and timestamps.
--- Use S_ISDIR(), S_ISREG(), etc. to check file type from mode.
local record Stat
  --- File size in bytes.
  size: function(self: Stat): number

  --- File mode (type and permissions).
  mode: function(self: Stat): number

  --- User ID of owner.
  uid: function(self: Stat): number

  --- Group ID of owner.
  gid: function(self: Stat): number

  --- Birth time (creation time) as Unix timestamp.
  birthtim: function(self: Stat): number

  --- Modification time as Unix timestamp.
  mtim: function(self: Stat): number

  --- Access time as Unix timestamp.
  atim: function(self: Stat): number

  --- Status change time as Unix timestamp.
  ctim: function(self: Stat): number

  --- Number of 512-byte blocks allocated.
  blocks: function(self: Stat): number

  --- Preferred I/O block size.
  blksize: function(self: Stat): number

  --- Inode number.
  ino: function(self: Stat): number

  --- Device ID containing the file.
  dev: function(self: Stat): number

  --- Device ID if special file.
  rdev: function(self: Stat): number

  --- Number of hard links.
  nlink: function(self: Stat): any

  --- Generation number.
  gen: function(self: Stat): any

  --- File flags.
  flags: function(self: Stat): any
end

--- Signal set for blocking, unblocking, and waiting on signals.
--- Used with sigprocmask(), sigaction(), and sigsuspend().
local record Sigset
  add: function(self: Sigset, sig: number)
  remove: function(self: Sigset, sig: number)
  fill: function(self: Sigset)
  clear: function(self: Sigset)
  contains: function(self: Sigset, sig: number): boolean
  __repr: function(self: Sigset): string
  __tostring: function(self: Sigset): string
end

--- Error information from system calls.
--- Provides detailed error codes and human-readable descriptions.
local record Errno
  --- Get the errno value.
  errno: function(self: Errno): number

  --- Get the Windows error code (if applicable).
  winerr: function(self: Errno): number

  --- Get the symbolic error name (e.g., "ENOENT").
  name: function(self: Errno): string

  --- Get the system call that failed.
  call: function(self: Errno): string

  --- Get a human-readable error description.
  doc: function(self: Errno): string

  --- Convert to string (delegates to doc()).
  __tostring: function(self: Errno): string
end

local record unix
  AF_INET: number
  AF_UNIX: number
  AF_UNSPEC: number
  ARG_MAX: number
  AT_EACCES: number
  AT_FDCWD: number
  AT_SYMLINK_NOFOLLOW: number
  BUFSIZ: number
  CLK_TCK: number
  CLOCK_REALTIME: number
  CLOCK_MONOTONIC: number
  CLOCK_BOOTTIME: number
  CLOCK_MONOTONIC_RAW: number
  CLOCK_REALTIME_COARSE: number
  CLOCK_MONOTONIC_COARSE: number
  CLOCK_THREAD_CPUTIME_ID: number
  CLOCK_PROCESS_CPUTIME_ID: number
  DT_BLK: number
  DT_CHR: number
  DT_DIR: number
  DT_FIFO: number
  DT_LNK: number
  DT_REG: number
  DT_SOCK: number
  DT_UNKNOWN: number
  E2BIG: number
  EACCES: number
  EADDRINUSE: number
  EADDRNOTAVAIL: number
  EAFNOSUPPORT: number
  EAGAIN: number
  EALREADY: number
  EBADF: number
  EBADFD: number
  EBADMSG: number
  EBUSY: number
  ECANCELED: number
  ECHILD: number
  ECONNABORTED: number
  ECONNREFUSED: number
  ECONNRESET: number
  EDEADLK: number
  EDESTADDRREQ: number
  EDOM: number
  EDQUOT: number
  EEXIST: number
  EFAULT: number
  EFBIG: number
  EHOSTDOWN: number
  EHOSTUNREACH: number
  EIDRM: number
  EILSEQ: number
  EINPROGRESS: number
  EINTR: number
  EINVAL: number
  EIO: number
  EISCONN: number
  EISDIR: number
  ELOOP: number
  EMFILE: number
  EMLINK: number
  EMSGSIZE: number
  ENAMETOOLONG: number
  ENETDOWN: number
  ENETRESET: number
  ENETUNREACH: number
  ENFILE: number
  ENOBUFS: number
  ENODATA: number
  ENODEV: number
  ENOENT: number
  ENOEXEC: number
  ENOLCK: number
  ENOMEM: number
  ENOMSG: number
  ENONET: number
  ENOPROTOOPT: number
  ENOSPC: number
  ENOSYS: number
  ENOTBLK: number
  ENOTCONN: number
  ENOTDIR: number
  ENOTEMPTY: number
  ENOTRECOVERABLE: number
  ENOTSOCK: number
  ENOTSUP: number
  ENOTTY: number
  ENXIO: number
  EOPNOTSUPP: number
  EOVERFLOW: number
  EOWNERDEAD: number
  EPERM: number
  EPFNOSUPPORT: number
  EPIPE: number
  EPROTO: number
  EPROTONOSUPPORT: number
  EPROTOTYPE: number
  ERANGE: number
  EREMOTE: number
  ERESTART: number
  EROFS: number
  ESHUTDOWN: number
  ESOCKTNOSUPPORT: number
  ESPIPE: number
  ESRCH: number
  ESTALE: number
  ETIME: number
  ETIMEDOUT: number
  ETOOMANYREFS: number
  ETXTBSY: number
  EUSERS: number
  EXDEV: number
  FD_CLOEXEC: number
  F_GETFD: number
  F_GETFL: number
  F_OK: number
  F_RDLCK: number
  F_SETFD: number
  F_SETFL: number
  F_SETLK: number
  F_SETLKW: number
  F_UNLCK: number
  F_WRLCK: number
  IPPROTO_ICMP: number
  IPPROTO_IP: number
  IPPROTO_RAW: number
  IPPROTO_TCP: number
  IPPROTO_UDP: number
  IP_HDRINCL: number
  IP_MTU: number
  IP_TOS: number
  IP_TTL: number
  ITIMER_PROF: number
  ITIMER_REAL: number
  ITIMER_VIRTUAL: number
  LOG_ALERT: number
  LOG_CRIT: number
  LOG_DEBUG: number
  LOG_EMERG: number
  LOG_ERR: number
  LOG_INFO: number
  LOG_NOTICE: number
  LOG_WARNING: number
  MSG_DONTROUTE: number
  MSG_MORE: number
  MSG_NOSIGNAL: number
  MSG_OOB: number
  MSG_PEEK: number
  MSG_WAITALL: number
  NAME_MAX: number
  NSIG: number
  O_RDONLY: number
  O_WRONLY: number
  O_RDWR: number
  O_CREAT: number
  O_TRUNC: number
  O_CLOEXEC: number
  O_EXCL: number
  O_APPEND: number
  O_NONBLOCK: number
  O_DIRECT: number
  O_DIRECTORY: number
  O_TMPFILE: number
  O_NOFOLLOW: number
  O_UNLINK: number
  O_DSYNC: number
  O_RSYNC: number
  O_SYNC: number
  O_NOATIME: number
  O_ACCMODE: number
  O_EXEC: number
  O_NOCTTY: number
  PATH_MAX: number
  PLEDGE_PENALTY_KILL_THREAD: number
  PLEDGE_PENALTY_KILL_PROCESS: number
  PLEDGE_PENALTY_RETURN_EPERM: number
  PLEDGE_STDERR_LOGGING: number
  PIPE_BUF: number
  POLLERR: number
  POLLHUP: number
  POLLIN: number
  POLLNVAL: number
  POLLOUT: number
  POLLPRI: number
  POLLRDBAND: number
  POLLRDHUP: number
  POLLRDNORM: number
  POLLWRBAND: number
  POLLWRNORM: number
  RLIMIT_AS: number
  RLIMIT_CPU: number
  RLIMIT_FSIZE: number
  RLIMIT_NOFILE: number
  RLIMIT_NPROC: number
  RLIMIT_RSS: number
  PRIO_PROCESS: number
  PRIO_PGRP: number
  PRIO_USER: number
  RUSAGE_BOTH: number
  RUSAGE_CHILDREN: number
  RUSAGE_SELF: number
  RUSAGE_THREAD: number
  R_OK: number
  SA_NOCLDSTOP: number
  SA_NOCLDWAIT: number
  SA_NODEFER: number
  SA_RESETHAND: number
  SA_RESTART: number
  SEEK_CUR: number
  SEEK_END: number
  SEEK_SET: number
  SHUT_RD: number
  SHUT_WR: number
  SHUT_RDWR: number
  SIGABRT: number
  SIGALRM: number
  SIGBUS: number
  SIGCHLD: number
  SIGCONT: number
  SIGEMT: number
  SIGFPE: number
  SIGHUP: number
  SIGILL: number
  SIGINFO: number
  SIGINT: number
  SIGIO: number
  SIGKILL: number
  SIGPIPE: number
  SIGPROF: number
  SIGPWR: number
  SIGQUIT: number
  SIGRTMAX: number
  SIGRTMIN: number
  SIGSEGV: number
  SIGSTKFLT: number
  SIGSTOP: number
  SIGSYS: number
  SIGTERM: number
  SIGTRAP: number
  SIGTSTP: number
  SIGTTIN: number
  SIGTTOU: number
  SIGURG: number
  SIGUSR1: number
  SIGUSR2: number
  SIGVTALRM: number
  SIGWINCH: number
  SIGXCPU: number
  SIGXFSZ: number
  SIG_BLOCK: number
  SIG_DFL: number
  SIG_IGN: number
  SIG_SETMASK: number
  SIG_UNBLOCK: number
  SOCK_CLOEXEC: number
  SOCK_DGRAM: number
  SOCK_NONBLOCK: number
  SOCK_RAW: number
  SOCK_RDM: number
  SOCK_SEQPACKET: number
  SOCK_STREAM: number
  SOL_IP: number
  SOL_SOCKET: number
  SOL_TCP: number
  SOL_UDP: number
  SO_ACCEPTCONN: number
  SO_BROADCAST: number
  SO_DEBUG: number
  SO_DONTROUTE: number
  SO_ERROR: number
  SO_KEEPALIVE: number
  SO_LINGER: number
  SO_RCVBUF: number
  SO_RCVLOWAT: number
  SO_RCVTIMEO: number
  SO_REUSEADDR: number
  SO_REUSEPORT: number
  SO_SNDBUF: number
  SO_SNDLOWAT: number
  SO_SNDTIMEO: number
  SO_TYPE: number
  TCP_CORK: number
  TCP_DEFER_ACCEPT: number
  TCP_FASTOPEN: number
  TCP_FASTOPEN_CONNECT: number
  TCP_KEEPCNT: number
  TCP_KEEPIDLE: number
  TCP_KEEPINTVL: number
  TCP_MAXSEG: number
  TCP_NODELAY: number
  TCP_NOTSENT_LOWAT: number
  TCP_QUICKACK: number
  TCP_SAVED_SYN: number
  TCP_SAVE_SYN: number
  TCP_SYNCNT: number
  TCP_WINDOW_CLAMP: number
  UTIME_NOW: number
  UTIME_OMIT: number
  WNOHANG: number
  WUNTRACED: number
  WCONTINUED: number
  W_OK: number
  X_OK: number

  open: function(path: string, flags: number, mode?: number, dirfd?: number): number
  close: function(fd: number): boolean
  read: function(fd: number, bufsiz?: number, offset?: number): string
  write: function(fd: number, data: string, offset?: number): number
  exit: function(exitcode?: number)
  environ: function(): {string:string}
  setenv: function(name: string, value: string, overwrite?: boolean)
  unsetenv: function(name: string)
  clearenv: function()
  getlogin: function()
  fork: function(): number
  commandv: function(prog: string): string
  execve: function(prog: string, args: {string}, env: {string}): nil
  execvp: function(prog: string, argv?: {string}): nil
  execvpe: function(prog: string, argv: {string}, envp?: {string}): nil
  fexecve: function(fd: number, argv: {string}, envp?: {string}): nil
  spawn: function(prog: string, argv: {string}, envp?: {string}): number
  spawnp: function(prog: string, argv: {string}, envp?: {string}): number
  dup: function(oldfd: number, newfd?: number, flags?: number, lowest?: number): number
  pipe: function(flags?: number): number, number
  wait: function(pid?: number, options?: number): number, number, Rusage
  WIFEXITED: function(wstatus: number): boolean
  WEXITSTATUS: function(wstatus: number): number
  WIFSIGNALED: function(wstatus: number): boolean
  WTERMSIG: function(wstatus: number): number
  getpid: function(): number
  getppid: function(): number
  kill: function(pid: number, sig: number): boolean
  killpg: function(pgrp: number, sig: number): boolean
  raise: function(sig: number): number
  access: function(path: string, how: number, flags?: number, dirfd?: number): boolean
  mkdir: function(path: string, mode?: number, dirfd?: number): boolean
  makedirs: function(path: string, mode?: number): boolean
  mkdtemp: function(template: string): string
  mkstemp: function(template: string): number
  chdir: function(path: string): boolean
  unlink: function(path: string, dirfd?: number): boolean
  rmdir: function(path: string, dirfd?: number): boolean
  rename: function(oldpath: string, newpath: string, olddirfd: number, newdirfd: number): boolean
  link: function(existingpath: string, newpath: string, flags: number, olddirfd: number, newdirfd: number): boolean
  symlink: function(target: string, linkpath: string, newdirfd?: number): boolean
  readlink: function(path: string, dirfd?: number): string
  realpath: function(path: string): string
  utimensat: function(path: string, asecs: number, ananos: number, msecs: number, mnanos: number, dirfd?: number, flags?: number): number
  futimens: function(fd: number, asecs: number, ananos: number, msecs: number, mnanos: number): number
  chown: function(path: string, uid: number, gid: number, flags?: number, dirfd?: number): boolean
  chmod: function(path: string, mode: number, flags?: number, dirfd?: number): boolean
  getcwd: function(): string
  rmrf: function(path: string): boolean
  fcntl: function(fd: number, cmd: number, ...: any): any
  getsid: function(pid: number): number
  getpgrp: function(): number
  setpgrp: function(): number
  setpgid: function(pid: number, pgid: number): boolean
  getpgid: function(pid: number)
  setsid: function(): number
  daemon: function(nochdir?: boolean, noclose?: boolean): boolean
  getuid: function(): number
  getgid: function(): number
  geteuid: function(): number
  getegid: function(): number
  chroot: function(path: string): boolean
  setuid: function(uid: number): boolean
  setfsuid: function(uid: number): boolean
  setgid: function(gid: number): boolean
  setresuid: function(real: number, effective: number, saved: number): boolean
  setresgid: function(real: number, effective: number, saved: number): boolean
  umask: function(newmask: number): number
  syslog: function(priority: number, msg: string)
  clock_gettime: function(clock?: number): number
  nanosleep: function(seconds: number, nanos?: number): number
  sync: function()
  fsync: function(fd: number): boolean
  fdatasync: function(fd: number): boolean
  lseek: function(fd: number, offset: number, whence?: number): number
  truncate: function(path: string, length?: number): boolean
  ftruncate: function(fd: number, length?: number): boolean
  socket: function(family?: number, type?: number, protocol?: number): number
  socketpair: function(family?: number, type?: number, protocol?: number): number
  bind: function(fd: number, ip?: number, port?: number): boolean
  siocgifconf: function(): any
  getsockopt: function(fd: number, level: number, optname: number): number
  setsockopt: function(fd: number, level: number, optname: number, value: boolean): boolean
  poll: function(fds: {number:number}, timeoutms?: number): {number:number}
  gethostname: function(): string
  listen: function(fd: number, backlog?: number): boolean
  accept: function(serverfd: number, flags?: number): number
  connect: function(fd: number, ip: number, port: number): boolean
  getsockname: function(fd: number): number
  getpeername: function(fd: number): number
  recv: function(fd: number, bufsiz?: number, flags?: number): string
  recvfrom: function(fd: number, bufsiz?: number, flags?: number): string
  send: function(fd: number, data: string, flags?: number): number
  sendto: function(fd: number, data: string, ip: number, port: number, flags?: number): number
  shutdown: function(fd: number, how: number): boolean
  sigprocmask: function(how: number, newmask: Sigset): Sigset
  sigaction: function(sig: number, handler?: function, flags?: number, mask?: Sigset): function
  sigsuspend: function(mask?: Sigset): nil
  setitimer: function(which: number, intervalsec: number, intervalns: number, valuesec: number, valuens: number): number
  strsignal: function(sig: number): string
  setrlimit: function(resource: number, soft: number, hard?: number): boolean
  getrlimit: function(resource: number): number
  nice: function(inc: number): number
  getpriority: function(which: number, who: number): number
  setpriority: function(which: number, who: number, prio: number): boolean
  getrusage: function(who?: number): Rusage
  pledge: function(promises?: string, execpromises?: string, mode?: number): boolean
  unveil: function(path: string, permissions: string): boolean
  gmtime: function(unixts: number): number, number, number, number, number, number, number, number, number, number, string
  localtime: function(unixts: number): number, number, number, number, number, number, number, number, number, number, string
  stat: function(path: string, flags?: number, dirfd?: number): Stat
  S_ISDIR: function(mode: number): boolean
  S_ISREG: function(mode: number): boolean
  S_ISLNK: function(mode: number): boolean
  S_ISBLK: function(mode: number): boolean
  S_ISCHR: function(mode: number): boolean
  S_ISFIFO: function(mode: number): boolean
  S_ISSOCK: function(mode: number): boolean
  fstat: function(fd: number): Stat
  opendir: function(path: string): Dir
  fdopendir: function(): function
  isatty: function(fd: number): boolean
  tiocgwinsz: function(fd: number): number
  tmpfd: function(): number
  sched_yield: function()
  mapshared: function(size: number): Memory
  Sigset: function(sig: number, ...: number): Sigset
end

return unix

