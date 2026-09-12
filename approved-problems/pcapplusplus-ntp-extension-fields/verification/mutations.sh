#!/usr/bin/env bash

set -u

script_dir=$(cd "$(dirname "$0")" && pwd)
if [[ $# -lt 1 ]]; then
  echo "usage: $0 REFERENCE_CHECKOUT [RESULTS_DIRECTORY] [MUTANT ...]" >&2
  exit 2
fi
repo=$1
results_dir=${2:-"$script_dir/exact-artifact"}
image='public.ecr.aws/d3j8x8q7/olympus-base-cpp@sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321'
build_dir=build-ntp-extension-tests
scratch=$(mktemp -d)
header_file="$repo/Packet++/header/NtpLayer.h"
source_file="$repo/Packet++/src/NtpLayer.cpp"

mkdir -p "$results_dir/logs"
cp "$header_file" "$scratch/NtpLayer.h"
cp "$source_file" "$scratch/NtpLayer.cpp"
reference_hash=$(shasum -a 256 "$scratch/NtpLayer.h" "$scratch/NtpLayer.cpp" | shasum -a 256 | cut -d' ' -f1)

restore_reference() {
  cp "$scratch/NtpLayer.h" "$header_file"
  cp "$scratch/NtpLayer.cpp" "$source_file"
}

cleanup() {
  restore_reference
  rm -r "$scratch"
}
trap cleanup EXIT

apply_mutation() {
  case "$1" in
    exact_total_auth)
      perl -0pi -e 's/if \(!tail\.valid\)\n\t\t\t\treturn 0;/if (!tail.valid)\n\t\t\t\treturn 0;\n\t\t\tif (tail.extensionLength != 0)\n\t\t\t\treturn 0;/' "$source_file"
      ;;
    greedy_tail_as_extensions)
      perl -0pi -e 's/tailLength == 0 \|\| tailLength == 4 \|\| tailLength == sizeof\(ntp_v4_auth_md5\) \|\|\n\t\t    tailLength == sizeof\(ntp_v4_auth_sha1\)/tailLength == 0 || tailLength == 4/' "$source_file"
      perl -0pi -e 's/if \(lastFieldLength < 28\)/if (lastFieldLength < 16)/' "$source_file"
      ;;
    ignore_crypto_nak)
      perl -0pi -e 's/tailLength == 0 \|\| tailLength == 4 \|\|/tailLength == 0 ||/' "$source_file"
      perl -0pi -e 's/remaining == 4 \|\| remaining == sizeof/remaining == sizeof/' "$source_file"
      ;;
    require_all_fields_28)
      perl -0pi -e 's/if \(lastFieldLength < 16 \|\|/if (lastFieldLength < 28 ||/' "$source_file"
      ;;
    accept_final_16)
      perl -0pi -e 's/if \(lastFieldLength < 28\)/if (lastFieldLength < 16)/' "$source_file"
      ;;
    length_is_value_length)
      perl -0pi -e 's/offset \+= lastFieldLength;/offset += lastFieldLength + 4;/' "$source_file"
      ;;
    round_non_aligned_length)
      perl -0pi -e 's/if \(lastFieldLength < 16 \|\| lastFieldLength % 4 != 0 \|\| lastFieldLength > remaining\)\n\t\t\t\treturn result;/if (lastFieldLength < 16 || lastFieldLength > remaining)\n\t\t\t\treturn result;\n\t\t\tlastFieldLength = (lastFieldLength + 3) \& ~size_t(3);\n\t\t\tif (lastFieldLength > remaining)\n\t\t\t\treturn result;/' "$source_file"
      ;;
    omit_remaining_bound)
      perl -0pi -e 's/ \|\| lastFieldLength > remaining//' "$source_file"
      ;;
    whitelist_types)
      perl -0pi -e 's/return NtpExtensionField\(m_Data \+ sizeof\(ntp_header\)\);/NtpExtensionField field(m_Data + sizeof(ntp_header));\n\t\tif (field.getFieldType() >= 0xf000)\n\t\t\treturn NtpExtensionField();\n\t\treturn field;/' "$source_file"
      ;;
    collapse_duplicate_types)
      perl -0pi -e 's/return NtpExtensionField\(extensionStart \+ nextOffset\);/NtpExtensionField next(extensionStart + nextOffset);\n\t\tif (next.getFieldType() == field.getFieldType())\n\t\t\treturn getNextExtensionField(next);\n\t\treturn next;/' "$source_file"
      ;;
    extension_bytes_as_key_id)
      perl -0pi -e 's/if \(!tail\.valid\)\n\t\t\t\treturn 0;/if (!tail.valid)\n\t\t\t\treturn 0;\n\t\t\tif (tail.extensionLength != 0)\n\t\t\t{\n\t\t\t\tuint32_t keyID;\n\t\t\t\tmemcpy(\&keyID, m_Data + sizeof(ntp_header), sizeof(keyID));\n\t\t\t\treturn keyID;\n\t\t\t}/' "$source_file"
      ;;
    append_instead_of_before)
      perl -0pi -e 's/if \(field\.getFieldType\(\) == nextFieldType\)\n\t\t\t\treturn addExtensionFieldAt\(builder, offset\);/if (field.getFieldType() == nextFieldType)\n\t\t\t\tbreak;/' "$source_file"
      ;;
    preserve_stale_auth)
      perl -0pi -e 's/tail\.authenticationLength != 0 \|\| field\.isNull\(\)/field.isNull()/' "$source_file"
      ;;
    partial_authenticated_edit)
      perl -0pi -e 's/TailInfo tail = parseV4Tail\(\);\n\t\tNtpExtensionField field/TailInfo tail = parseV4Tail();\n\t\tif (tail.valid \&\& tail.authenticationLength != 0)\n\t\t{\n\t\t\textendLayer(static_cast<int>(sizeof(ntp_header) + tail.extensionLength), 4);\n\t\t\treturn NtpExtensionField();\n\t\t}\n\t\tNtpExtensionField field/' "$source_file"
      ;;
    detached_only)
      perl -0pi -e 's/TailInfo tail = parseV4Tail\(\);\n\t\tNtpExtensionField field/TailInfo tail = parseV4Tail();\n\t\tif (getPrevLayer() != nullptr)\n\t\t\treturn NtpExtensionField();\n\t\tNtpExtensionField field/' "$source_file"
      ;;
    normalize_key_id)
      perl -0pi -e 's/return header->keyID;/return netToHost32(header->keyID);/g' "$source_file"
      ;;
    discard_ntpv3_auth)
      perl -0pi -e 's/(case 3:\n\t\t\{\n)\t\t\tif \(m_DataLen < \(sizeof\(ntp_header\) \+ sizeof\(ntp_v3_auth\)\)\)\n\t\t\t\treturn 0;\n\n\t\t\tntp_v3_auth\* header = \(ntp_v3_auth\*\)\(m_Data \+ sizeof\(ntp_header\)\);\n\t\t\treturn header->keyID;/$1\t\t\treturn 0;/' "$source_file"
      perl -0pi -e 's/(case 3:\n\t\t\{\n)\t\t\tif \(m_DataLen < \(sizeof\(ntp_header\) \+ sizeof\(ntp_v3_auth\)\)\)\n\t\t\t\treturn std::string\(\);\n\n\t\t\tntp_v3_auth\* header = \(ntp_v3_auth\*\)\(m_Data \+ sizeof\(ntp_header\)\);\n\t\t\treturn byteArrayToHexString\(header->dgst, 8\);/$1\t\t\treturn std::string();/' "$source_file"
      ;;
    tighten_classifier)
      perl -0pi -e 's/return data \&\& dataSize >= sizeof\(ntp_header\);/return data \&\& dataSize >= sizeof(ntp_header) \&\& dataSize % 4 == 0;/' "$source_file"
      ;;
    nonzero_builder_padding)
      perl -0pi -e 's/m_Data\.resize\(fieldLength, 0\);/m_Data.resize(fieldLength, 0xff);/' "$source_file"
      ;;
    omit_builder_minimum)
      perl -0pi -e 's/if \(fieldLength < 16\)\n\t\t\tfieldLength = 16;/if (fieldLength < 4)\n\t\t\tfieldLength = 4;/' "$source_file"
      ;;
    accept_oversized_builder)
      perl -0pi -e 's/fieldDataLength > 65528/fieldDataLength > 65529/' "$source_file"
      perl -0pi -e 's/fieldLength > 65532/fieldLength > 65536/' "$source_file"
      ;;
    raw_type_endian)
      perl -0pi -e 's/return netToHost16\(fieldType\);/return fieldType;/' "$source_file"
      ;;
    raw_length_endian)
      perl -0pi -e 's/return netToHost16\(fieldLength\);/return fieldLength;/' "$source_file"
      ;;
    remove_all_duplicates)
      perl -0pi -e 's/return shortenLayer\(static_cast<int>\(sizeof\(ntp_header\) \+ offset\), field\.getTotalSize\(\)\);/return shortenLayer(sizeof(ntp_header), tail.extensionLength);/' "$source_file"
      ;;
    missing_target_fails)
      perl -0pi -e 's/\n\t\treturn addExtensionFieldAt\(builder, tail\.extensionLength\);\n\t\}\n\n\tbool NtpLayer::removeExtensionField/\n\t\treturn NtpExtensionField();\n\t}\n\n\tbool NtpLayer::removeExtensionField/' "$source_file"
      ;;
    empty_remove_all_fails)
      perl -0pi -e 's/if \(tail\.extensionLength == 0\)\n\t\t\treturn true;/if (tail.extensionLength == 0)\n\t\t\treturn false;/' "$source_file"
      ;;
    allow_malformed_append)
      perl -0pi -e 's/if \(lastFieldLength < 16 \|\| lastFieldLength % 4 != 0 \|\| lastFieldLength > remaining\)\n\t\t\t\treturn result;/if (lastFieldLength < 16 || lastFieldLength % 4 != 0 || lastFieldLength > remaining)\n\t\t\t\treturn { true, 0, 0 };/' "$source_file"
      ;;
    accept_foreign_cursor)
      perl -0pi -e 's/(uintptr_t startAddress = reinterpret_cast<uintptr_t>\(extensionStart\);\n)/$1\t\tif (!field.isNull() \&\& (fieldAddress < startAddress || fieldAddress >= startAddress + tail.extensionLength))\n\t\t\treturn NtpExtensionField(extensionStart);\n/' "$source_file"
      ;;
    unsafe_remove_short_final)
      perl -0pi -e 's/previousLength < 28/previousLength < 16/' "$source_file"
      ;;
    parse_ntpv3_extensions)
      perl -0pi -e 's/getVersion\(\) != 4 \|\| m_DataLen/getVersion() < 3 || m_DataLen/' "$source_file"
      ;;
    trim_zero_extension_data)
      perl -0pi -e 's/size_t totalSize = getTotalSize\(\);\n\t\treturn totalSize < 2 \* sizeof\(uint16_t\) \? 0 : totalSize - 2 \* sizeof\(uint16_t\);/size_t totalSize = getTotalSize();\n\t\tsize_t dataSize = totalSize < 2 * sizeof(uint16_t) ? 0 : totalSize - 2 * sizeof(uint16_t);\n\t\twhile (dataSize > 0 \&\& m_Data[2 * sizeof(uint16_t) + dataSize - 1] == 0)\n\t\t\t--dataSize;\n\t\treturn dataSize;/' "$source_file"
      ;;
    purge_keeps_pointer)
      perl -0pi -e 's/delete\[\] m_Data;\n\t\t\tm_Data = nullptr;/delete[] m_Data;/' "$header_file"
      ;;
    allow_authenticated_removal)
      perl -0pi -e 's/if \(!tail\.valid \|\| tail\.authenticationLength != 0\)\n\t\t\treturn false;/if (!tail.valid)\n\t\t\treturn false;/g' "$source_file"
      ;;
    *)
      return 2
      ;;
  esac
}

run_suite() {
  local name=$1
  local build_log="$results_dir/logs/$name-build.log"
  local focused_log="$results_dir/logs/$name-new.log"
  local full_build_log="$results_dir/logs/$name-base-build.log"
  local full_log="$results_dir/logs/$name-base.log"
  local build_rc focused_rc full_build_rc full_rc

  docker run --rm --network none --user "$(id -u):$(id -g)" -v "$repo:/app" -w /app "$image" \
    cmake --build "$build_dir" --target NtpExtensionTest --parallel 2 >"$build_log" 2>&1
  build_rc=$?
  focused_rc=not_run
  full_build_rc=not_run
  full_rc=not_run
  if [[ $build_rc -eq 0 ]]; then
    docker run --rm --network none --user "$(id -u):$(id -g)" -v "$repo:/app" -w /app "$image" \
      ctest --test-dir "$build_dir" --output-on-failure --timeout 15 -R '^NtpExtension\.' >"$focused_log" 2>&1
    focused_rc=$?
    if [[ $focused_rc -eq 0 ]]; then
      docker run --rm --network none --user "$(id -u):$(id -g)" -v "$repo:/app" -w /app "$image" \
        cmake --build "$build_dir" --target Packet++Test --parallel 2 >"$full_build_log" 2>&1
      full_build_rc=$?
      if [[ $full_build_rc -eq 0 ]]; then
        docker run --rm --network none --user "$(id -u):$(id -g)" -v "$repo:/app" -w /app "$image" \
          ctest --test-dir "$build_dir" --output-on-failure -R '^Packet\+\+Test$' >"$full_log" 2>&1
        full_rc=$?
      fi
    fi
  fi

  printf '%s\tbuild=%s\tnew=%s\tbase_build=%s\tbase=%s\n' \
    "$name" "$build_rc" "$focused_rc" "$full_build_rc" "$full_rc"
}

mutants=(
  exact_total_auth
  greedy_tail_as_extensions
  ignore_crypto_nak
  require_all_fields_28
  accept_final_16
  length_is_value_length
  round_non_aligned_length
  omit_remaining_bound
  whitelist_types
  collapse_duplicate_types
  extension_bytes_as_key_id
  append_instead_of_before
  preserve_stale_auth
  partial_authenticated_edit
  detached_only
  normalize_key_id
  discard_ntpv3_auth
  tighten_classifier
  nonzero_builder_padding
  omit_builder_minimum
  accept_oversized_builder
  raw_type_endian
  raw_length_endian
  remove_all_duplicates
  missing_target_fails
  empty_remove_all_fails
  allow_malformed_append
  accept_foreign_cursor
  unsafe_remove_short_final
  parse_ntpv3_extensions
  trim_zero_extension_data
  purge_keeps_pointer
  allow_authenticated_removal
)

if [[ $# -gt 2 ]]; then
  mutants=("${@:3}")
fi

for mutant in "${mutants[@]}"; do
  restore_reference
  apply_mutation "$mutant"
  mutant_hash=$(shasum -a 256 "$header_file" "$source_file" | shasum -a 256 | cut -d' ' -f1)
  if [[ "$mutant_hash" == "$reference_hash" ]]; then
    printf '%s\tmutation=no-op\n' "$mutant"
    continue
  fi
  run_suite "$mutant"
done

restore_reference
run_suite reference_restored
