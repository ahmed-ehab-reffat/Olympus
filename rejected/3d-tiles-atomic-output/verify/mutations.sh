#!/usr/bin/env bash
set -euo pipefail

SOURCE="src/tools/pipelines/PipelineExecutor.ts"
WORKSPACE="$(mktemp -d "${PWD}/.mutation-work.XXXXXX")"
ORIGINAL="$WORKSPACE/PipelineExecutor.ts"
cp "$SOURCE" "$ORIGINAL"

restore() {
  cp "$ORIGINAL" "$SOURCE"
  rm -rf "$WORKSPACE"
}
trap restore EXIT

run_mutation() {
  local name="$1"
  local expression="$2"
  cp "$ORIGINAL" "$SOURCE"
  perl -0pi -e "$expression" "$SOURCE"
  if cmp -s "$ORIGINAL" "$SOURCE"; then
    echo "$name: mutation did not change the source" >&2
    return 1
  fi

  local report="$WORKSPACE/$name.xml"
  local status=0
  ./test.sh new --output_path="$report" >/dev/null 2>&1 || status=$?
  local failures
  failures="$(node -e '
    const text = require("fs").readFileSync(process.argv[1], "utf8");
    const match = text.match(/<testsuites[^>]* failures="([0-9]+)"/);
    process.stdout.write(match ? match[1] : "0");
  ' "$report")"
  if [ "$status" -eq 0 ] || [ "$failures" -eq 0 ]; then
    echo "$name: focused suite did not reject mutation" >&2
    return 1
  fi
  echo "$name: rejected with $failures failed specs"
}

run_mutation direct_final_write \
  's/\? transaction\.stagedTarget/\? pipeline.output/'

run_mutation delete_destination_on_error \
  's/} catch \(error\) \{\n      failed = true;/} catch (error) {\n      if (transaction) {\n        fs.rmSync(transaction.destination, { recursive: true, force: true });\n      }\n      failed = true;/'

run_mutation file_only_staging \
  's/\? transaction\.stagedTarget/\? path.extname(transaction.stagedStorage) === ""\n            ? pipeline.output\n            : transaction.stagedTarget/'

run_mutation no_directory_seed \
  's/path\.extname\(transaction\.stagedStorage\) === "" &&/false &&/'

run_mutation incorrect_json_resolution \
  's/const isJson = extension === "\.json";/const isJson = false;/'

run_mutation cleanup_only_on_success \
  's/PipelineExecutor\.cleanup\(intermediateWorkspace\);/if (!failed) PipelineExecutor.cleanup(intermediateWorkspace);/; s/if \(transaction && !transaction\.retainWorkspace\)/if (!failed \&\& transaction \&\& !transaction.retainWorkspace)/'

run_mutation delete_custom_temp_base \
  's/PipelineExecutor\.cleanup\(intermediateWorkspace\);/PipelineExecutor.cleanup(PipelineExecutor.tempBaseDirectory ?? intermediateWorkspace);/'

run_mutation wrong_package_staging_shape \
  's/extension === "" \|\| isJson \? "staged" : `staged\$\{originalExtension\}`/"staged"/'

run_mutation require_existing_destination_parent \
  's/const owner = PipelineExecutor\.findExistingDirectory\(\n      path\.dirname\(destination\)\n    \);/const owner = path.dirname(destination);/'

run_mutation create_parents_before_processing \
  's/(transaction = PipelineExecutor\.createOutputTransaction\(pipeline\.output\);)/$1\n      PipelineExecutor.createDestinationParents(transaction);\n      transaction.createdParents = [];/'

run_mutation delete_workspace_ancestry \
  's/PipelineExecutor\.cleanup\(transaction\.workspace\);/PipelineExecutor.cleanup(path.dirname(transaction.workspace));/'
