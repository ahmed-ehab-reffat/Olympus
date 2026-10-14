---
Repository: https://github.com/pytest-dev/pyfakefs
Issue: N/A
Commit: 796c48eb7830e3ee7fb57eb368dc115c1f3436ba
Language: Python
Category: feature-request
Title: Add advisory file locking to the fake fcntl and os modules
---

# Add advisory file locking to the fake fcntl and os modules

Add advisory file locking for fake files. Today `fcntl.flock`, `fcntl.fcntl` and `fcntl.lockf` do nothing on a fake descriptor, `os.lockf` is handed to the real `os` module, and closing the original of a descriptor made by `os.dup` breaks the copy. Make the three `fcntl` functions and `os.lockf` lock fake files by the rules below; `os.lockf` must be faked also when it is imported by name from `os`. The `fcntl` functions accept a descriptor or any object with `fileno()`, and the `fcntl.fcntl` lock commands take and return a `struct flock` packed in the host's native layout.

There are three kinds of lock. Record locks (`F_SETLK`, `F_SETLKW`, `fcntl.lockf`, `os.lockf`) belong to the process. Open file description locks (`F_OFD_SETLK`, `F_OFD_SETLKW`) and `flock` locks belong to the open file description the descriptor refers to. Record and description locks share one byte-range table per file and conflict whenever their owners differ, so the process's record locks never conflict with each other but do conflict with its own description locks. `flock` locks are independent of both and conflict only between different descriptions. Locks belong to the file itself, not to the path it was opened through, and every fake filesystem starts without any.

A byte-range request replaces whatever the same owner held on that range: unlocking the middle of a lock splits it, and touching or overlapping locks of the same type and owner merge. `l_whence` makes the start relative to the beginning of the file, the description's current offset or the file's current size. A length of 0 covers everything from the start on, however far the file grows, and a negative length covers the bytes just before the start; a range that would start before 0 is `EINVAL`. A read lock needs a descriptor open for reading and a write lock one open for writing, otherwise `EBADF`; `flock` ignores the mode. `os.lockf` takes write locks starting at the descriptor's current offset, and its `F_TEST` succeeds only when nothing but the process's own record locks is in the way, otherwise it raises `EACCES`.

A refused non-blocking request raises `EAGAIN` and changes nothing. A request that would have to wait can never be granted inside the fake, so it raises `EDEADLK` instead of waiting, and also changes nothing, except that a refused `flock` conversion between shared and exclusive leaves the description with no `flock` lock at all.

`F_GETLK` and `F_OFD_GETLK` describe the conflicting lock that starts lowest: its type, `l_whence` 0, its absolute start, its length (0 when it has no end), and `l_pid` set to the process id for a record lock or -1 for a description lock. Without a conflict they change only `l_type`, to `F_UNLCK`.

A descriptor from `os.dup` or `os.dup2`, and a file object opened on an existing descriptor, refer to the same open file description as that descriptor, and closing one of them leaves the others working. The process's record locks on a file are all released as soon as it closes any descriptor for that file, whichever description or path the descriptor came through. Description locks are released when the last descriptor of their description is closed. `os.dup2` onto an open descriptor closes that descriptor first, exactly as `os.close` would.
