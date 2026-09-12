#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import url from "node:url";

const taskDirectory = path.resolve(
  path.dirname(url.fileURLToPath(import.meta.url)),
  ".."
);
const dockerfilePath = path.join(taskDirectory, "Dockerfile");
const lockPath = path.join(taskDirectory, "package-lock.json");

const lockText = fs.readFileSync(lockPath, "utf8");
const lock = JSON.parse(lockText);
if (lock.name !== "3d-tiles-tools" || lock.packages?.[""]?.name !== lock.name) {
  throw new Error("package-lock.json does not describe the upstream package");
}

// BuildKit includes each Docker instruction in its progress output. The
// evaluator reads that output with asyncio's default 64 KiB line limit, so one
// instruction containing the full lockfile can prevent the image build from
// even starting. Split only at existing line boundaries and keep each
// instruction comfortably below that limit.
const maximumLockPartBytes = 12 * 1024;
const lockParts = [];
let lockPart = "";
for (const line of lockText.match(/[^\n]*\n|[^\n]+$/g) ?? []) {
  if (
    lockPart.length > 0 &&
    Buffer.byteLength(lockPart + line) > maximumLockPartBytes
  ) {
    lockParts.push(lockPart);
    lockPart = "";
  }
  if (Buffer.byteLength(line) > maximumLockPartBytes) {
    throw new Error("package-lock.json contains an unexpectedly long line");
  }
  lockPart += line;
}
if (lockPart.length > 0) {
  lockParts.push(lockPart);
}

const lockInstructions = lockParts
  .map((part, index) => {
    const suffix = String(index).padStart(2, "0");
    const redirect = index === 0 ? ">" : ">>";
    return `RUN <<'RUNTIME_PACKAGE_LOCK_PART_${suffix}'
set -eu
cat ${redirect} package-lock.json <<'RUNTIME_PACKAGE_LOCK_JSON_${suffix}'
${part}RUNTIME_PACKAGE_LOCK_JSON_${suffix}
RUNTIME_PACKAGE_LOCK_PART_${suffix}`;
  })
  .join("\n\n");

const dockerfile = `FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

LABEL org.opencontainers.image.title="3d-tiles-atomic-output" \\
      org.opencontainers.image.revision="bounded-plain-lock-v13" \\
      io.olympus.upstream.revision="8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff" \\
      io.olympus.upstream.package-sha256="96eeef23741ad4083921b842d942dabef642dce477f77870cbdeb7242a1c82b2"

WORKDIR /app
COPY . .

# The pristine upstream build context has no lockfile and task-side files cannot
# be copied into it. Keep this plain, reviewable mirror synchronized with the
# canonical task package-lock.json by running verify/sync-docker-lock.mjs. The
# bounded instructions prevent build progress output from exceeding the
# evaluator's subprocess line limit.
${lockInstructions}

RUN set -eu; \\
    npm ci --include=dev --no-audit --no-fund; \\
    npm cache clean --force

CMD ["/bin/bash"]
`;

fs.writeFileSync(dockerfilePath, dockerfile);
process.stdout.write(`Synchronized ${dockerfilePath} from ${lockPath}\n`);
