# Verification

Build the image from a pristine checkout at
`98d3b401e4fada626122b9846a5b4f9dd1d5d741`:

```sh
cp /path/to/problems/str0m-remote-renegotiation/Dockerfile .
docker build -t str0m-remote-offer-test .
```

Then run:

```sh
/path/to/problems/str0m-remote-renegotiation/verify/gates.sh
```

The script mounts this problem folder read-only, starts the image with
`--network none`, and checks:

| State | Mode | Expected |
|---|---|---|
| `test.patch` only | `base` | pass, 31 tests |
| `test.patch` only | `new` | fail |
| `test.patch` + `solution.patch` | `new` | pass, 6 tests |
| `test.patch` + `solution.patch` | `base` | pass, 31 tests |

It also verifies that all four JUnit files are well formed when Python is
available in the image.
