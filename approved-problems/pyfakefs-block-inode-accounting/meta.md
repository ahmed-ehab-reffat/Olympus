---
Repository: https://github.com/pytest-dev/pyfakefs
Issue: N/A
Commit: c72885ac79a45f553fd76a06c2735739e289ecbc
Language: Python
Category: feature-request
Title: Add block, inode and reserve accounting to fake filesystem mounts
---

# Add block, inode and reserve accounting to fake filesystem mounts

`add_mount_point` gains `block_size` (default 1), `inode_count` (default `None`, no limit), `reserved_blocks` and `reserved_inodes` (default 0). `set_disk_usage(total_size, path=None, ...)` takes the same four after `path`, each defaulting to `None`, which keeps the current value; it changes the mount containing `path`, or the root mount without one. A block size below 1, or a negative count or reserve, is a `ValueError`. A finite mount's total size is rounded down to whole blocks, and `get_disk_usage` reports that rounded byte total. With `total_size=None` nothing is refused for lack of space; the reported total is then a fixed whole-block placeholder, and the usage figures derive from it. Changing the block size of a mount that holds something raises `OSError` with `EBUSY`; lowering the inode count below the number in use raises `ENOSPC`; a refused change leaves every setting as it was.

A regular file occupies as many whole blocks as its byte length needs, a directory none. A symbolic link is charged the same way for the path it holds, not its target. Rewriting inside a block it already has does not grow an object; shrinking gives the rest back.

An object takes an inode when it first appears on a mount and gives it and its blocks back when its last name goes, even while it stays open. A hard link takes no inode. Renaming within a mount changes neither count. Mount roots, directories created while establishing a mount point, and the filesystem's temporary directory are charged to no mount.

An operation that cannot fit in the available blocks or inodes raises `OSError` with `ENOSPC` and leaves the mount as it was. If `create_dir`, `create_file`, `create_symlink` or `add_real_file` fails, any parent directories it created are removed. `os.makedirs`, `Path.mkdir(parents=True)`, `add_real_directory` and `add_real_paths` commit each step alone, keeping earlier steps. An exhausted inode count does not stop writes to existing objects. A reserve is free but only root may take it: anyone else gets `ENOSPC` once only the reserve is left, and `get_disk_usage` reports available, not free.

`FakeFilesystem.statvfs(path)` and a new `FakeOsModule.statvfs(path)` report that path's mount as an `os.statvfs_result`; `statvfs` imported directly from `os` is patched too. `f_bsize` and `f_frsize` are the block size. `f_blocks`, `f_bfree` and `f_bavail` are the total, free, and free-less-reserve blocks. `f_files`, `f_ffree` and `f_favail` are the same for inodes, `f_flag` is 0, `f_namemax` is 255, and no field goes below zero. A mount with no inode limit reports as many inodes as blocks. `mount_usages()` returns an `os.statvfs_result` for every mount, keyed by mount path. `reset` keeps the block size, inode count and reserves of the root mount.

`tree_usage(path)` returns what `path` and everything below took from each mount, as a dict of mount path to a `(size, inodes)` pair. Each object counts once regardless of hard links. An object charged to no mount contributes nothing. A symlink is charged itself, but not followed. `one_file_system=True` stops the walk at a directory on another mount.
