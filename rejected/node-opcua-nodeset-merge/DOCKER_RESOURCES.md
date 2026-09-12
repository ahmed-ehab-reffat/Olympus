# Docker resource archive

The task-specific Docker images below were inventoried before cleanup. No
matching container or volume existed. The unrelated active
`olympus-environment-gate-12213` image/container belongs to
`rmk-hid-transport-handoff` and was intentionally excluded.

| Tag | Image ID | Platform | Inspect size | Created |
|---|---|---|---:|---|
| `olympus-node-opcua-amd64-r8:latest` | `sha256:ad92b77a76c5ce1e73766a28fed6af9b12446b07d0458e4430bec3208a2293d9` | `linux/amd64` | 557,746,557 | 2026-08-11T09:08:20Z |
| `olympus-node-opcua-amd64-probe:latest` | `sha256:6141de9ab0efea38747e4191f0aa16e0c8f93615374628429cfc26974dc09398` | `linux/amd64` | 636,185,865 | 2026-08-11T08:45:55Z |
| `olympus-node-opcua-rev5-pinned:latest` | `sha256:c063ac39e992f14a884df4cc1569fe4b63c46245db611d6be5bb9fa669587f36` | `linux/arm64` | 520,044,830 | 2026-08-11T02:52:42Z |
| `olympus-node-opcua-rev5-cold:latest` | `sha256:69033f2fd881479e8c3413e90a5e1c4f48f092c2c3b8142205e1e099083ca0e7` | `linux/arm64` | 520,046,635 | 2026-08-11T02:48:11Z |
| `node-opcua-nodeset-merge-phase-a:latest` | `sha256:3cd8e7fd0dd15ee2711e9d31542597b0d3445d1d9802c7dc9bc0a493db4ee699` | `linux/arm64` | 520,508,102 | 2026-08-10T17:55:25Z |

The final `linux/amd64` revision-8 image is preserved as
`payloads/olympus-node-opcua-amd64-r8.tar.gz` and can be restored with:

```sh
gzip -dc payloads/olympus-node-opcua-amd64-r8.tar.gz | docker image load
```

Historical images are reproducible from the archived repository pin and
Dockerfile records. Their binary layers were not duplicated into the archive.

Six reclaimable, unshared BuildKit records explicitly identified by the
node-opcua build commands were also removed:

- `qiic1gc574ksack66e63oer00` — 374.8 MB
- `wlnugjgh25v014feoca9jp88t` — 386.4 MB
- `eu3zoofizpcoyfm5gqyv5zpmv` — 528.6 MB
- `z1v8kkv5ncsvc0lo0eiyri6kf` — 528.6 MB
- `w2jmuio0p4llh0rbb3r733iwr` — 529.6 MB
- `9vnfghh6npyslsh0owe7n7r3u` — 648.3 MB

Their unshared task-specific parent records were traced back through `COPY` and
`WORKDIR` and removed as well:

- `yig6mtbumypt6339dp2ruq4fb` — 56.75 MB
- `xfewnhrz343s2fr86kd4l8ify` — 56.75 MB
- `f3pg39woe3aq2u8tna5e2kzrc` — 56.75 MB
- `k60l6u1586du34m00hnu90qgl` — 57.71 MB
- `nineacs3e58wfww3y0qzca9r6` — 164.8 MB
- `qy7ldbnfoqp6xzrgq8u2re9d0` — 164.8 MB
- `jxw6alsr6cc92uzyh6qipkfd0` — 4.128 kB
- `k9ypuu1mv9h8aino9fy25azks` — 4.128 kB

Traversal stopped at the two shared TypeScript base-image records; those were
not pruned.

Shared base images, unrelated containers, unrelated volumes, and unrelated
BuildKit records were not changed.
