# TwelveMonkeys SGI writer

Status: **closed — rejected for plagiarism/similarity on 2026-08-01**

Repository: `haraldk/TwelveMonkeys`

Pinned commit: `41aaf3b1bc7fe8144b3bbd16c62d13a559feb7c5`

This problem adds a complete SGI ImageIO writer across provider discovery, standard source selection, 8/16-bit planar output, uncompressed and RLE encoding, RLE row tables, and interoperability with the existing reader.

The exact base lane passes 91 tests with two skips. The new lane fails on the pinned repository, then passes 24 tests with the reference solution. The same solved lanes pass inside the built container with networking disabled. The false-positive audit killed independent orientation, 16-bit atom-width, and subsampling-offset mutants and found no actionable survivor in the attempted set.

The problem was rejected by the external plagiarism/similarity gate before solver calibration began. The technically valid artifacts and verification evidence are retained only as a durable rejection record. Do not submit, calibrate, reword, or lightly rescope this task. Reconsider TwelveMonkeys only through a materially different subsystem and behavior after a fresh similarity audit.
