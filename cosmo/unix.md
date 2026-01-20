# unix

Type declarations for the `unix` module.

## Types

### Memory

```teal
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
```

### Dir

```teal
local record Dir
  close: function(self: Dir): boolean
  read: function(self: Dir): string
  fd: function(self: Dir): number
  tell: function(self: Dir): number
  rewind: function(self: Dir)
end
```

### Rusage

```teal
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
```

### Stat

```teal
local record Stat
  size: function(self: Stat): number
  mode: function(self: Stat): number
  uid: function(self: Stat): number
  gid: function(self: Stat): number
  birthtim: function(self: Stat): number
  mtim: function(self: Stat): number
  atim: function(self: Stat): number
  ctim: function(self: Stat): number
  blocks: function(self: Stat): number
  blksize: function(self: Stat): number
  ino: function(self: Stat): number
  dev: function(self: Stat): number
  rdev: function(self: Stat): number
  nlink: function(self: Stat): any
  gen: function(self: Stat): any
  flags: function(self: Stat): any
end
```

### Sigset

```teal
local record Sigset
  add: function(self: Sigset, sig: number)
  remove: function(self: Sigset, sig: number)
  fill: function(self: Sigset)
  clear: function(self: Sigset)
  contains: function(self: Sigset, sig: number): boolean
  __repr: function(self: Sigset): string
  __tostring: function(self: Sigset): string
end
```

### Errno

```teal
local record Errno
  errno: function(self: Errno): number
  winerr: function(self: Errno): number
  name: function(self: Errno): string
  call: function(self: Errno): string
  doc: function(self: Errno): string
  __tostring: function(self: Errno): string
end
```

### unix Constants

Constants defined in the unix module.

```teal
local record unix Constants
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
end
```

## Functions

### open

```teal
function open(path: string, flags: number, mode?: number, dirfd?: number): number
```

**Parameters:**

- `path` (string)
- `flags` (number)
- `mode` (number)
- `dirfd` (number)

**Returns:**

- number

### close

```teal
function close(fd: number): boolean
```

**Parameters:**

- `fd` (number)

**Returns:**

- boolean

### read

```teal
function read(fd: number, bufsiz?: number, offset?: number): string
```

**Parameters:**

- `fd` (number)
- `bufsiz` (number)
- `offset` (number)

**Returns:**

- string

### write

```teal
function write(fd: number, data: string, offset?: number): number
```

**Parameters:**

- `fd` (number)
- `data` (string)
- `offset` (number)

**Returns:**

- number

### exit

```teal
function exit(exitcode?: number)
```

**Parameters:**

- `exitcode` (number)

### environ

```teal
function environ(): {string:string}
```

**Returns:**

- {string:string}

### setenv

```teal
function setenv(name: string, value: string, overwrite?: boolean)
```

**Parameters:**

- `name` (string)
- `value` (string)
- `overwrite` (boolean)

### unsetenv

```teal
function unsetenv(name: string)
```

**Parameters:**

- `name` (string)

### clearenv

```teal
function clearenv()
```

### getlogin

```teal
function getlogin()
```

### fork

```teal
function fork(): number
```

**Returns:**

- number

### commandv

```teal
function commandv(prog: string): string
```

**Parameters:**

- `prog` (string)

**Returns:**

- string

### execve

```teal
function execve(prog: string, args: {string}, env: {string}): nil
```

**Parameters:**

- `prog` (string)
- `args` ({string})
- `env` ({string})

**Returns:**

- nil

### execvp

```teal
function execvp(prog: string, argv?: {string}): nil
```

**Parameters:**

- `prog` (string)
- `argv` ({string})

**Returns:**

- nil

### execvpe

```teal
function execvpe(prog: string, argv: {string}, envp?: {string}): nil
```

**Parameters:**

- `prog` (string)
- `argv` ({string})
- `envp` ({string})

**Returns:**

- nil

### fexecve

```teal
function fexecve(fd: number, argv: {string}, envp?: {string}): nil
```

**Parameters:**

- `fd` (number)
- `argv` ({string})
- `envp` ({string})

**Returns:**

- nil

### spawn

```teal
function spawn(prog: string, argv: {string}, envp?: {string}): number
```

**Parameters:**

- `prog` (string)
- `argv` ({string})
- `envp` ({string})

**Returns:**

- number

### spawnp

```teal
function spawnp(prog: string, argv: {string}, envp?: {string}): number
```

**Parameters:**

- `prog` (string)
- `argv` ({string})
- `envp` ({string})

**Returns:**

- number

### dup

```teal
function dup(oldfd: number, newfd?: number, flags?: number, lowest?: number): number
```

**Parameters:**

- `oldfd` (number)
- `newfd` (number)
- `flags` (number)
- `lowest` (number)

**Returns:**

- number

### pipe

```teal
function pipe(flags?: number): number, number
```

**Parameters:**

- `flags` (number)

**Returns:**

- number
- number

### wait

```teal
function wait(pid?: number, options?: number): number, number, Rusage
```

**Parameters:**

- `pid` (number)
- `options` (number)

**Returns:**

- number
- number
- Rusage

### WIFEXITED

```teal
function WIFEXITED(wstatus: number): boolean
```

**Parameters:**

- `wstatus` (number)

**Returns:**

- boolean

### WEXITSTATUS

```teal
function WEXITSTATUS(wstatus: number): number
```

**Parameters:**

- `wstatus` (number)

**Returns:**

- number

### WIFSIGNALED

```teal
function WIFSIGNALED(wstatus: number): boolean
```

**Parameters:**

- `wstatus` (number)

**Returns:**

- boolean

### WTERMSIG

```teal
function WTERMSIG(wstatus: number): number
```

**Parameters:**

- `wstatus` (number)

**Returns:**

- number

### getpid

```teal
function getpid(): number
```

**Returns:**

- number

### getppid

```teal
function getppid(): number
```

**Returns:**

- number

### kill

```teal
function kill(pid: number, sig: number): boolean
```

**Parameters:**

- `pid` (number)
- `sig` (number)

**Returns:**

- boolean

### killpg

```teal
function killpg(pgrp: number, sig: number): boolean
```

**Parameters:**

- `pgrp` (number)
- `sig` (number)

**Returns:**

- boolean

### raise

```teal
function raise(sig: number): number
```

**Parameters:**

- `sig` (number)

**Returns:**

- number

### access

```teal
function access(path: string, how: number, flags?: number, dirfd?: number): boolean
```

**Parameters:**

- `path` (string)
- `how` (number)
- `flags` (number)
- `dirfd` (number)

**Returns:**

- boolean

### mkdir

```teal
function mkdir(path: string, mode?: number, dirfd?: number): boolean
```

**Parameters:**

- `path` (string)
- `mode` (number)
- `dirfd` (number)

**Returns:**

- boolean

### makedirs

```teal
function makedirs(path: string, mode?: number): boolean
```

**Parameters:**

- `path` (string)
- `mode` (number)

**Returns:**

- boolean

### mkdtemp

```teal
function mkdtemp(template: string): string
```

**Parameters:**

- `template` (string)

**Returns:**

- string

### mkstemp

```teal
function mkstemp(template: string): number
```

**Parameters:**

- `template` (string)

**Returns:**

- number

### chdir

```teal
function chdir(path: string): boolean
```

**Parameters:**

- `path` (string)

**Returns:**

- boolean

### unlink

```teal
function unlink(path: string, dirfd?: number): boolean
```

**Parameters:**

- `path` (string)
- `dirfd` (number)

**Returns:**

- boolean

### rmdir

```teal
function rmdir(path: string, dirfd?: number): boolean
```

**Parameters:**

- `path` (string)
- `dirfd` (number)

**Returns:**

- boolean

### rename

```teal
function rename(oldpath: string, newpath: string, olddirfd: number, newdirfd: number): boolean
```

**Parameters:**

- `oldpath` (string)
- `newpath` (string)
- `olddirfd` (number)
- `newdirfd` (number)

**Returns:**

- boolean

### link

```teal
function link(existingpath: string, newpath: string, flags: number, olddirfd: number, newdirfd: number): boolean
```

**Parameters:**

- `existingpath` (string)
- `newpath` (string)
- `flags` (number)
- `olddirfd` (number)
- `newdirfd` (number)

**Returns:**

- boolean

### symlink

```teal
function symlink(target: string, linkpath: string, newdirfd?: number): boolean
```

**Parameters:**

- `target` (string)
- `linkpath` (string)
- `newdirfd` (number)

**Returns:**

- boolean

### readlink

```teal
function readlink(path: string, dirfd?: number): string
```

**Parameters:**

- `path` (string)
- `dirfd` (number)

**Returns:**

- string

### realpath

```teal
function realpath(path: string): string
```

**Parameters:**

- `path` (string)

**Returns:**

- string

### utimensat

```teal
function utimensat(path: string, asecs: number, ananos: number, msecs: number, mnanos: number, dirfd?: number, flags?: number): number
```

**Parameters:**

- `path` (string)
- `asecs` (number)
- `ananos` (number)
- `msecs` (number)
- `mnanos` (number)
- `dirfd` (number)
- `flags` (number)

**Returns:**

- number

### futimens

```teal
function futimens(fd: number, asecs: number, ananos: number, msecs: number, mnanos: number): number
```

**Parameters:**

- `fd` (number)
- `asecs` (number)
- `ananos` (number)
- `msecs` (number)
- `mnanos` (number)

**Returns:**

- number

### chown

```teal
function chown(path: string, uid: number, gid: number, flags?: number, dirfd?: number): boolean
```

**Parameters:**

- `path` (string)
- `uid` (number)
- `gid` (number)
- `flags` (number)
- `dirfd` (number)

**Returns:**

- boolean

### chmod

```teal
function chmod(path: string, mode: number, flags?: number, dirfd?: number): boolean
```

**Parameters:**

- `path` (string)
- `mode` (number)
- `flags` (number)
- `dirfd` (number)

**Returns:**

- boolean

### getcwd

```teal
function getcwd(): string
```

**Returns:**

- string

### rmrf

```teal
function rmrf(path: string): boolean
```

**Parameters:**

- `path` (string)

**Returns:**

- boolean

### fcntl

```teal
function fcntl(fd: number, cmd: number, ...: any): any
```

**Parameters:**

- `fd` (number)
- `cmd` (number)
- `...` (any)

**Returns:**

- any

### getsid

```teal
function getsid(pid: number): number
```

**Parameters:**

- `pid` (number)

**Returns:**

- number

### getpgrp

```teal
function getpgrp(): number
```

**Returns:**

- number

### setpgrp

```teal
function setpgrp(): number
```

**Returns:**

- number

### setpgid

```teal
function setpgid(pid: number, pgid: number): boolean
```

**Parameters:**

- `pid` (number)
- `pgid` (number)

**Returns:**

- boolean

### getpgid

```teal
function getpgid(pid: number)
```

**Parameters:**

- `pid` (number)

### setsid

```teal
function setsid(): number
```

**Returns:**

- number

### daemon

```teal
function daemon(nochdir?: boolean, noclose?: boolean): boolean
```

**Parameters:**

- `nochdir` (boolean)
- `noclose` (boolean)

**Returns:**

- boolean

### getuid

```teal
function getuid(): number
```

**Returns:**

- number

### getgid

```teal
function getgid(): number
```

**Returns:**

- number

### geteuid

```teal
function geteuid(): number
```

**Returns:**

- number

### getegid

```teal
function getegid(): number
```

**Returns:**

- number

### chroot

```teal
function chroot(path: string): boolean
```

**Parameters:**

- `path` (string)

**Returns:**

- boolean

### setuid

```teal
function setuid(uid: number): boolean
```

**Parameters:**

- `uid` (number)

**Returns:**

- boolean

### setfsuid

```teal
function setfsuid(uid: number): boolean
```

**Parameters:**

- `uid` (number)

**Returns:**

- boolean

### setgid

```teal
function setgid(gid: number): boolean
```

**Parameters:**

- `gid` (number)

**Returns:**

- boolean

### setresuid

```teal
function setresuid(real: number, effective: number, saved: number): boolean
```

**Parameters:**

- `real` (number)
- `effective` (number)
- `saved` (number)

**Returns:**

- boolean

### setresgid

```teal
function setresgid(real: number, effective: number, saved: number): boolean
```

**Parameters:**

- `real` (number)
- `effective` (number)
- `saved` (number)

**Returns:**

- boolean

### umask

```teal
function umask(newmask: number): number
```

**Parameters:**

- `newmask` (number)

**Returns:**

- number

### syslog

```teal
function syslog(priority: number, msg: string)
```

**Parameters:**

- `priority` (number)
- `msg` (string)

### clock_gettime

```teal
function clock_gettime(clock?: number): number
```

**Parameters:**

- `clock` (number)

**Returns:**

- number

### nanosleep

```teal
function nanosleep(seconds: number, nanos?: number): number
```

**Parameters:**

- `seconds` (number)
- `nanos` (number)

**Returns:**

- number

### sync

```teal
function sync()
```

### fsync

```teal
function fsync(fd: number): boolean
```

**Parameters:**

- `fd` (number)

**Returns:**

- boolean

### fdatasync

```teal
function fdatasync(fd: number): boolean
```

**Parameters:**

- `fd` (number)

**Returns:**

- boolean

### lseek

```teal
function lseek(fd: number, offset: number, whence?: number): number
```

**Parameters:**

- `fd` (number)
- `offset` (number)
- `whence` (number)

**Returns:**

- number

### truncate

```teal
function truncate(path: string, length?: number): boolean
```

**Parameters:**

- `path` (string)
- `length` (number)

**Returns:**

- boolean

### ftruncate

```teal
function ftruncate(fd: number, length?: number): boolean
```

**Parameters:**

- `fd` (number)
- `length` (number)

**Returns:**

- boolean

### socket

```teal
function socket(family?: number, type?: number, protocol?: number): number
```

**Parameters:**

- `family` (number)
- `type` (number)
- `protocol` (number)

**Returns:**

- number

### socketpair

```teal
function socketpair(family?: number, type?: number, protocol?: number): number
```

**Parameters:**

- `family` (number)
- `type` (number)
- `protocol` (number)

**Returns:**

- number

### bind

```teal
function bind(fd: number, ip?: number, port?: number): boolean
```

**Parameters:**

- `fd` (number)
- `ip` (number)
- `port` (number)

**Returns:**

- boolean

### siocgifconf

```teal
function siocgifconf(): any
```

**Returns:**

- any

### getsockopt

```teal
function getsockopt(fd: number, level: number, optname: number): number
```

**Parameters:**

- `fd` (number)
- `level` (number)
- `optname` (number)

**Returns:**

- number

### setsockopt

```teal
function setsockopt(fd: number, level: number, optname: number, value: boolean): boolean
```

**Parameters:**

- `fd` (number)
- `level` (number)
- `optname` (number)
- `value` (boolean)

**Returns:**

- boolean

### poll

```teal
function poll(fds: {number:number}, timeoutms?: number): {number:number}
```

**Parameters:**

- `fds` ({number:number})
- `timeoutms` (number)

**Returns:**

- {number:number}

### gethostname

```teal
function gethostname(): string
```

**Returns:**

- string

### listen

```teal
function listen(fd: number, backlog?: number): boolean
```

**Parameters:**

- `fd` (number)
- `backlog` (number)

**Returns:**

- boolean

### accept

```teal
function accept(serverfd: number, flags?: number): number
```

**Parameters:**

- `serverfd` (number)
- `flags` (number)

**Returns:**

- number

### connect

```teal
function connect(fd: number, ip: number, port: number): boolean
```

**Parameters:**

- `fd` (number)
- `ip` (number)
- `port` (number)

**Returns:**

- boolean

### getsockname

```teal
function getsockname(fd: number): number
```

**Parameters:**

- `fd` (number)

**Returns:**

- number

### getpeername

```teal
function getpeername(fd: number): number
```

**Parameters:**

- `fd` (number)

**Returns:**

- number

### recv

```teal
function recv(fd: number, bufsiz?: number, flags?: number): string
```

**Parameters:**

- `fd` (number)
- `bufsiz` (number)
- `flags` (number)

**Returns:**

- string

### recvfrom

```teal
function recvfrom(fd: number, bufsiz?: number, flags?: number): string
```

**Parameters:**

- `fd` (number)
- `bufsiz` (number)
- `flags` (number)

**Returns:**

- string

### send

```teal
function send(fd: number, data: string, flags?: number): number
```

**Parameters:**

- `fd` (number)
- `data` (string)
- `flags` (number)

**Returns:**

- number

### sendto

```teal
function sendto(fd: number, data: string, ip: number, port: number, flags?: number): number
```

**Parameters:**

- `fd` (number)
- `data` (string)
- `ip` (number)
- `port` (number)
- `flags` (number)

**Returns:**

- number

### shutdown

```teal
function shutdown(fd: number, how: number): boolean
```

**Parameters:**

- `fd` (number)
- `how` (number)

**Returns:**

- boolean

### sigprocmask

```teal
function sigprocmask(how: number, newmask: Sigset): Sigset
```

**Parameters:**

- `how` (number)
- `newmask` (Sigset)

**Returns:**

- Sigset

### sigaction

```teal
function sigaction(sig: number, handler?: function, flags?: number, mask?: Sigset): function
```

**Parameters:**

- `sig` (number)
- `handler` (function)
- `flags` (number)
- `mask` (Sigset)

**Returns:**

- function

### sigsuspend

```teal
function sigsuspend(mask?: Sigset): nil
```

**Parameters:**

- `mask` (Sigset)

**Returns:**

- nil

### setitimer

```teal
function setitimer(which: number, intervalsec: number, intervalns: number, valuesec: number, valuens: number): number
```

**Parameters:**

- `which` (number)
- `intervalsec` (number)
- `intervalns` (number)
- `valuesec` (number)
- `valuens` (number)

**Returns:**

- number

### strsignal

```teal
function strsignal(sig: number): string
```

**Parameters:**

- `sig` (number)

**Returns:**

- string

### setrlimit

```teal
function setrlimit(resource: number, soft: number, hard?: number): boolean
```

**Parameters:**

- `resource` (number)
- `soft` (number)
- `hard` (number)

**Returns:**

- boolean

### getrlimit

```teal
function getrlimit(resource: number): number
```

**Parameters:**

- `resource` (number)

**Returns:**

- number

### nice

```teal
function nice(inc: number): number
```

**Parameters:**

- `inc` (number)

**Returns:**

- number

### getpriority

```teal
function getpriority(which: number, who: number): number
```

**Parameters:**

- `which` (number)
- `who` (number)

**Returns:**

- number

### setpriority

```teal
function setpriority(which: number, who: number, prio: number): boolean
```

**Parameters:**

- `which` (number)
- `who` (number)
- `prio` (number)

**Returns:**

- boolean

### getrusage

```teal
function getrusage(who?: number): Rusage
```

**Parameters:**

- `who` (number)

**Returns:**

- Rusage

### pledge

```teal
function pledge(promises?: string, execpromises?: string, mode?: number): boolean
```

**Parameters:**

- `promises` (string)
- `execpromises` (string)
- `mode` (number)

**Returns:**

- boolean

### unveil

```teal
function unveil(path: string, permissions: string): boolean
```

**Parameters:**

- `path` (string)
- `permissions` (string)

**Returns:**

- boolean

### gmtime

```teal
function gmtime(unixts: number): number, number, number, number, number, number, number, number, number, number, string
```

**Parameters:**

- `unixts` (number)

**Returns:**

- number
- number
- number
- number
- number
- number
- number
- number
- number
- number
- string

### localtime

```teal
function localtime(unixts: number): number, number, number, number, number, number, number, number, number, number, string
```

**Parameters:**

- `unixts` (number)

**Returns:**

- number
- number
- number
- number
- number
- number
- number
- number
- number
- number
- string

### stat

```teal
function stat(path: string, flags?: number, dirfd?: number): Stat
```

**Parameters:**

- `path` (string)
- `flags` (number)
- `dirfd` (number)

**Returns:**

- Stat

### S_ISDIR

```teal
function S_ISDIR(mode: number): boolean
```

**Parameters:**

- `mode` (number)

**Returns:**

- boolean

### S_ISREG

```teal
function S_ISREG(mode: number): boolean
```

**Parameters:**

- `mode` (number)

**Returns:**

- boolean

### S_ISLNK

```teal
function S_ISLNK(mode: number): boolean
```

**Parameters:**

- `mode` (number)

**Returns:**

- boolean

### S_ISBLK

```teal
function S_ISBLK(mode: number): boolean
```

**Parameters:**

- `mode` (number)

**Returns:**

- boolean

### S_ISCHR

```teal
function S_ISCHR(mode: number): boolean
```

**Parameters:**

- `mode` (number)

**Returns:**

- boolean

### S_ISFIFO

```teal
function S_ISFIFO(mode: number): boolean
```

**Parameters:**

- `mode` (number)

**Returns:**

- boolean

### S_ISSOCK

```teal
function S_ISSOCK(mode: number): boolean
```

**Parameters:**

- `mode` (number)

**Returns:**

- boolean

### fstat

```teal
function fstat(fd: number): Stat
```

**Parameters:**

- `fd` (number)

**Returns:**

- Stat

### opendir

```teal
function opendir(path: string): Dir
```

**Parameters:**

- `path` (string)

**Returns:**

- Dir

### fdopendir

```teal
function fdopendir(): function
```

**Returns:**

- function

### isatty

```teal
function isatty(fd: number): boolean
```

**Parameters:**

- `fd` (number)

**Returns:**

- boolean

### tiocgwinsz

```teal
function tiocgwinsz(fd: number): number
```

**Parameters:**

- `fd` (number)

**Returns:**

- number

### tmpfd

```teal
function tmpfd(): number
```

**Returns:**

- number

### sched_yield

```teal
function sched_yield()
```

### mapshared

```teal
function mapshared(size: number): Memory
```

**Parameters:**

- `size` (number)

**Returns:**

- Memory

### Sigset

```teal
function Sigset(sig: number, ...: number): Sigset
```

**Parameters:**

- `sig` (number)
- `...` (number)

**Returns:**

- Sigset
