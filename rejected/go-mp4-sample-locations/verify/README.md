# Verification

Build the image from the untouched pinned checkout, using the problem
Dockerfile with that checkout as the build context:

```sh
docker build -t go-mp4-sample-locations:verify \
  -f /path/to/problems/go-mp4-sample-locations/Dockerfile \
  /path/to/go-mp4
```

`gates.sh` applies the test patch inside that image with networking disabled.
It expects base pass, new fail, then applies the solution and expects new pass
and base pass. It also exercises every accepted output-path placement and
parses all four JUnit files.

```sh
./verify/gates.sh
```

`mutate.py` expects a solved checkout containing both patches. Run it in the
same image so it uses the offline Go cache:

```sh
docker run --rm --network none \
  -v /path/to/solved/go-mp4:/app \
  -v /path/to/problems/go-mp4-sample-locations/verify:/verify:ro \
  go-mp4-sample-locations:verify python3 /verify/mutate.py /app
```

The expected result is 12 killed mutations, each producing at least two public
assertion failures, followed by restoration of the unmodified `probe.go`.
