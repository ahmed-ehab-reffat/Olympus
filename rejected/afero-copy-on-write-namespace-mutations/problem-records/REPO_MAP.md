# REPO MAP - Afero copy-on-write namespace mutations

| Path | Relevance |
|---|---|
| `afero.go` | Public `Fs` and `File` contracts plus shared errors. |
| `copyOnWriteFs.go` | Target composition, lookup precedence, copy-up, and current `EPERM` namespace behavior. |
| `unionFile.go` | Merged directory iteration and existing copy helpers. |
| `composite_test.go` | Existing merged-directory and copy-on-write behavior. |
| `copyOnWriteFs_test.go` | Existing constructor and mkdir behavior. |
| `afero_test.go` | Generic remove and rename expectations. |
| `memmap_test.go` | Directory-tree rename and recreation behavior. |
| `basepath.go` | OS-backed independent-root composition and symlink portability limitation. |
| `readonlyfs.go` / `lstater.go` / `symlink.go` | Base wrapping and optional interface surfaces. |
| `README.md` | Public sandboxing and composition narrative. |

The root module is the complete evaluator scope. Nested `gcsfs` and `sftpfs`
modules are separate and not required for this core composition enhancement.
