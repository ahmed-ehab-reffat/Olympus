#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import url from "node:url";
import childProcess from "node:child_process";

const taskDirectory = path.resolve(
  path.dirname(url.fileURLToPath(import.meta.url)),
  ".."
);
const dockerfilePath = path.join(taskDirectory, "Dockerfile");
const lockfilePath = path.join(taskDirectory, "package-lock.json");
const sourceDirectory = path.resolve(process.argv[2] ?? "");

const expected = {
  revision: "8c4ef2fc77a464d3da42fbfdefb8d4b675c263ff",
  sourcePackage:
    "96eeef23741ad4083921b842d942dabef642dce477f77870cbdeb7242a1c82b2",
  lock: "4074d13c92a36903bda81ba611d747dae460686966786eac3ff287b545685711",
  packageCount: 711,
  base: "FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest",
};
const allowedAdditions = {
  copyfiles: "2.4.1",
  tsx: "4.20.3",
};

function fail(message) {
  throw new Error(message);
}

function hash(data) {
  return crypto.createHash("sha256").update(data).digest("hex");
}

function assertEqual(actual, wanted, label) {
  if (actual !== wanted) {
    fail(`${label}: expected ${wanted}, received ${actual}`);
  }
}

function assertObjectEqual(actual, wanted, label) {
  const sortKeys = (value) => {
    if (Array.isArray(value)) {
      return value.map(sortKeys);
    }
    if (value && typeof value === "object") {
      return Object.fromEntries(
        Object.entries(value)
          .sort(([left], [right]) => left.localeCompare(right))
          .map(([key, entryValue]) => [key, sortKeys(entryValue)])
      );
    }
    return value;
  };
  const actualText = JSON.stringify(sortKeys(actual));
  const wantedText = JSON.stringify(sortKeys(wanted));
  if (actualText !== wantedText) {
    fail(`${label} differs\nexpected ${wantedText}\nreceived ${actualText}`);
  }
}

if (!process.argv[2]) {
  fail("usage: node verify/docker-environment.mjs /path/to/3d-tiles-tools");
}

const dockerfile = fs.readFileSync(dockerfilePath, "utf8");
assertEqual(dockerfile.split(/\r?\n/, 1)[0], expected.base, "base image");
const remoteFetch = dockerfile.match(
  /(?:^\s*(?:RUN\s+)?(?:curl|wget)\b[^\n]*https?:\/\/)|(?:^\s*ADD\s+https?:\/\/)/im
);
if (remoteFetch) {
  fail(`Dockerfile contains a direct remote-file fetch: ${remoteFetch[0]}`);
}
if (/(?:^|&&|;|\|)\s*(?:RUN\s+)?(?:base64|gzip)\s+/m.test(dockerfile)) {
  fail("Dockerfile contains an encoded or compressed payload command");
}
if (/cat\s+>\s+package\.json\b/.test(dockerfile)) {
  fail("Dockerfile authors a replacement package manifest");
}
const canonicalLockBytes = fs.readFileSync(lockfilePath);
assertEqual(hash(canonicalLockBytes), expected.lock, "canonical package lock hash");
const canonicalLock = JSON.parse(canonicalLockBytes);
const lockMatches = [
  ...dockerfile.matchAll(
    /cat (>|>>) package-lock\.json <<'RUNTIME_PACKAGE_LOCK_JSON_(\d+)'\n([\s\S]*?)RUNTIME_PACKAGE_LOCK_JSON_\2/g
  ),
];
if (lockMatches.length === 0) {
  fail("could not locate the bounded plain package lock mirror");
}
for (let index = 0; index < lockMatches.length; index++) {
  const [, redirect, suffix, part] = lockMatches[index];
  assertEqual(Number(suffix), index, "Docker package lock part order");
  assertEqual(
    redirect,
    index === 0 ? ">" : ">>",
    `Docker package lock part ${suffix} redirect`
  );
  if (Buffer.byteLength(part) > 12 * 1024) {
    fail(`Docker package lock part ${suffix} exceeds its output-safe limit`);
  }
}
const mirroredLockBytes = Buffer.from(
  lockMatches.map((match) => match[3]).join("")
);
assertEqual(
  mirroredLockBytes.equals(canonicalLockBytes),
  true,
  "Docker package lock mirror"
);
assertEqual(
  Object.keys(canonicalLock.packages ?? {}).length,
  expected.packageCount,
  "locked package count"
);

const sourcePackagePath = path.join(sourceDirectory, "package.json");
const sourcePackageBytes = fs.readFileSync(sourcePackagePath);
assertEqual(
  hash(sourcePackageBytes),
  expected.sourcePackage,
  "upstream package manifest hash"
);
const sourcePackage = JSON.parse(sourcePackageBytes);

const revision = childProcess
  .execFileSync("git", ["-C", sourceDirectory, "rev-parse", "HEAD"], {
    encoding: "utf8",
  })
  .trim();
assertEqual(revision, expected.revision, "upstream revision");

const lockRoot = canonicalLock.packages?.[""];
if (!lockRoot) {
  fail("package lock has no root package");
}
assertEqual(canonicalLock.name, sourcePackage.name, "locked package name");
assertEqual(lockRoot.name, sourcePackage.name, "locked root package name");
assertObjectEqual(
  lockRoot.dependencies,
  sourcePackage.dependencies,
  "locked root dependencies"
);
assertObjectEqual(
  lockRoot.devDependencies,
  { ...sourcePackage.devDependencies, ...allowedAdditions },
  "locked root development dependencies"
);

for (const [packagePath, packageEntry] of Object.entries(
  canonicalLock.packages ?? {}
)) {
  if (
    packagePath &&
    packageEntry.resolved?.startsWith("https://registry.npmjs.org/") &&
    !packageEntry.integrity
  ) {
    fail(`${packagePath} has a registry URL without an integrity hash`);
  }
}

process.stdout.write(
  `Docker environment audit passed: ${expected.packageCount} locked packages, ` +
    `upstream ${expected.revision}, no direct remote-file fetches.\n`
);
