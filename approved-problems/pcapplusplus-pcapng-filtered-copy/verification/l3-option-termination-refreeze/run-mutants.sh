#!/usr/bin/env bash

set -u

repo="$(cat /tmp/pcapng-l3-state-root.txt)/combined"
source_file="$repo/Pcap++/src/PcapFileDevice.cpp"
backup=/tmp/pcapng-l3-reference-PcapFileDevice.cpp
image=pcapplusplus-pcapng-filtered-copy-problem:latest-base
results=/tmp/pcapng-l3-mutant-results.txt

cp "$source_file" "$backup"
: >"$results"

for mutant in $(seq 1 28); do
  cp "$backup" "$source_file"
  case "$mutant" in
    1)
      name=wrong_custom_constant
      perl -0pi -e 's/constexpr uint32_t DecryptionSecrets = 10, DoNotCopyCustom = 0x40000bad;/constexpr uint32_t DecryptionSecrets = 10, DoNotCopyCustom = 0x00000bad;/' "$source_file"
      ;;
    2)
      name=drop_both_custom_types
      perl -0pi -e 's/else if \(blockType == DoNotCopyCustom\)\n\t\t\t\tkeep = false;/else if (blockType == DoNotCopyCustom || blockType == 0x00000bad)\n\t\t\t\tkeep = false;/' "$source_file"
      ;;
    3)
      name=never_filter_spb
      perl -0pi -e 's/timespec timestamp = \{\};\n\t\t\t\tkeep = m_BpfWrapper\.matches\(block \+ 12, capturedLength, timestamp, interfaces\[0\]\.first\);/keep = true;/' "$source_file"
      ;;
    4)
      name=never_filter_epb
      perl -0pi -e 's/timespec timestamp = \{\};\n\t\t\t\tkeep = m_BpfWrapper\.matches\(block \+ 28, capturedLength, timestamp, interfaces\[interfaceId\]\.first\);/keep = true;/' "$source_file"
      ;;
    5)
      name=count_shb_in_finite_length
      perl -0pi -e 's/output\.size\(\) - outputSectionContent/output.size() - outputSectionHeader/' "$source_file"
      perl -0pi -e 's/size_t outputSectionContent = 0;/size_t outputSectionContent = 0;\n\t\t(void)outputSectionContent;/' "$source_file"
      ;;
    6)
      name=carry_interfaces_across_sections
      perl -0pi -e 's/\n\t\t\t\tinterfaces\.clear\(\);//' "$source_file"
      ;;
    7)
      name=weak_trailing_length_check
      perl -0pi -e 's/readPcapNg<uint32_t>\(block \+ blockLength - 4, order\) != blockLength/readPcapNg<uint32_t>(block + blockLength - 4, order) < 12/' "$source_file"
      ;;
    8)
      name=isb_only_reject_uint32_max
      perl -0pi -e 's/readPcapNg<uint32_t>\(block \+ 8, order\) >= interfaces\.size\(\)/readPcapNg<uint32_t>(block + 8, order) == UINT32_MAX/' "$source_file"
      ;;
    9)
      name=copy_obsolete_packet
      perl -0pi -e 's/else if \(blockType == ObsoletePacket\)\n\t\t\t\treturn fail\("obsolete packet blocks are unsupported"\);/else if (blockType == ObsoletePacket)\n\t\t\t\tkeep = true;/' "$source_file"
      ;;
    10)
      name=truncate_destination_before_validation
      perl -0pi -e 's/(bool PcapNgFileReaderDevice::copyFiltered\(const std::string& outputFileName\) const\n\t\{)/$1\n\t\tstd::ofstream prematureOutput(outputFileName, std::ios::binary | std::ios::trunc);\n\t\tprematureOutput.close();/' "$source_file"
      ;;
    11)
      name=require_reader_open
      perl -0pi -e 's/(bool PcapNgFileReaderDevice::copyFiltered\(const std::string& outputFileName\) const\n\t\{)/$1\n\t\tif (m_LightPcapNg == nullptr)\n\t\t\treturn false;/' "$source_file"
      ;;
    12)
      name=spb_ignore_snap_length
      perl -0pi -e 's/const uint32_t capturedLength =\n\t\t\t\t    interfaces\[0\]\.second == 0 \? originalLength : std::min\(originalLength, interfaces\[0\]\.second\);/const uint32_t capturedLength = originalLength;/' "$source_file"
      ;;
    13)
      name=all_sections_little_endian
      perl -0pi -e 's/order = PcapNgByteOrder::Big;/order = PcapNgByteOrder::Little;/' "$source_file"
      ;;
    14)
      name=normalize_epb_timestamp_byte
      perl -0pi -e 's/output\.insert\(output\.end\(\), block, block \+ blockLength\);/output.insert(output.end(), block, block + blockLength);\n\t\t\t\tif (blockType == EnhancedPacket)\n\t\t\t\t\toutput[output.size() - blockLength + 12] ^= 1;/' "$source_file"
      ;;
    15)
      name=drop_opaque_metadata
      perl -0pi -e 's/bool keep = true;/bool keep = blockType == SectionHeader || blockType == InterfaceDescription ||\n\t\t\t            blockType == EnhancedPacket || blockType == SimplePacket ||\n\t\t\t            blockType == InterfaceStatistics || blockType == 0x00000bad;/' "$source_file"
      ;;
    16)
      name=reject_nonzero_epb_interface
      perl -0pi -e 's/interfaceId >= interfaces\.size\(\)/interfaceId != 0 || interfaceId >= interfaces.size()/' "$source_file"
      ;;
    17)
      name=retain_only_first_idb
      perl -0pi -e 's/interfaces\.emplace_back\(readPcapNg<uint16_t>\(block \+ 8, order\),\n\t\t\t\t                        readPcapNg<uint32_t>\(block \+ 12, order\)\);/if (interfaces.empty())\n\t\t\t\t\tinterfaces.emplace_back(readPcapNg<uint16_t>(block + 8, order),\n\t\t\t\t\t                        readPcapNg<uint32_t>(block + 12, order));\n\t\t\t\telse\n\t\t\t\t\tkeep = false;/' "$source_file"
      ;;
    18)
      name=filter_epb_with_interface_zero
      perl -0pi -e 's/interfaces\[interfaceId\]\.first/interfaces[0].first/' "$source_file"
      ;;
    19)
      name=strip_do_not_copy_custom_option
      perl -0pi -e 's!\n\t\t// Magic numbers for different pcap formats!\n\t\tstd::vector<uint8_t> stripDoNotCopyCustomOption(const uint8_t* block, uint32_t blockLength,\n\t\t                                                 size_t optionsOffset, PcapNgByteOrder order)\n\t\t{\n\t\t\tstd::vector<uint8_t> rewritten(block, block + blockLength);\n\t\t\tconst size_t optionsEnd = blockLength - 4;\n\t\t\twhile (optionsOffset + 4 <= optionsEnd)\n\t\t\t{\n\t\t\t\tconst uint16_t type = readPcapNg<uint16_t>(block + optionsOffset, order);\n\t\t\t\tconst uint16_t length = readPcapNg<uint16_t>(block + optionsOffset + 2, order);\n\t\t\t\tconst size_t fieldLength = 4 + ((static_cast<size_t>(length) + 3) & ~size_t(3));\n\t\t\t\tif (fieldLength > optionsEnd - optionsOffset)\n\t\t\t\t\tbreak;\n\t\t\t\tif (type == 19373)\n\t\t\t\t{\n\t\t\t\t\trewritten.erase(rewritten.begin() + optionsOffset,\n\t\t\t\t\t                rewritten.begin() + optionsOffset + fieldLength);\n\t\t\t\t\tconst uint32_t rewrittenLength = static_cast<uint32_t>(rewritten.size());\n\t\t\t\t\twritePcapNg<uint32_t>(rewritten.data() + 4, rewrittenLength, order);\n\t\t\t\t\twritePcapNg<uint32_t>(rewritten.data() + rewrittenLength - 4, rewrittenLength, order);\n\t\t\t\t\tbreak;\n\t\t\t\t}\n\t\t\t\toptionsOffset += fieldLength;\n\t\t\t}\n\t\t\treturn rewritten;\n\t\t}\n\n\t\t// Magic numbers for different pcap formats!' "$source_file"
      perl -0pi -e 's!\t\t\t\toutput\.insert\(output\.end\(\), block, block \+ blockLength\);!\t\t\t\tif (blockType == InterfaceDescription)\n\t\t\t\t{\n\t\t\t\t\tconst auto rewritten = stripDoNotCopyCustomOption(block, blockLength, 16, order);\n\t\t\t\t\toutput.insert(output.end(), rewritten.begin(), rewritten.end());\n\t\t\t\t}\n\t\t\t\telse\n\t\t\t\t\toutput.insert(output.end(), block, block + blockLength);!' "$source_file"
      ;;
    20)
      name=accept_overrun_option
      perl -0pi -e 's/if \(!advancePcapNgField\(optionsOffset, optionLength, optionsEnd\)\)\n\t\t\t\t\treturn false;/if (!advancePcapNgField(optionsOffset, optionLength, optionsEnd))\n\t\t\t\t\treturn true;/' "$source_file"
      ;;
    21)
      name=accept_overrun_nrb_record
      perl -0pi -e 's/if \(!advancePcapNgField\(recordOffset, recordLength, recordsEnd\)\)\n\t\t\t\t\treturn false;/if (!advancePcapNgField(recordOffset, recordLength, recordsEnd))\n\t\t\t\t{\n\t\t\t\t\toptionsOffset = recordsEnd;\n\t\t\t\t\treturn true;\n\t\t\t\t}/' "$source_file"
      ;;
    22)
      name=accept_extra_spb_payload
      perl -0pi -e 's/16 \+ paddedLength != blockLength/16 + paddedLength > blockLength/' "$source_file"
      ;;
    23)
      name=skip_shb_option_validation
      perl -0pi -e 's/!validatePcapNgOptions\(block, blockLength, 24, order\)/false/' "$source_file"
      ;;
    24)
      name=skip_isb_option_validation
      perl -0pi -e 's/!validatePcapNgOptions\(block, blockLength, 20, order\)/false/' "$source_file"
      ;;
    25)
      name=skip_nrb_option_validation
      perl -0pi -e 's/!validatePcapNgOptions\(block, blockLength, optionsOffset, order\)/false/' "$source_file"
      ;;
    26)
      name=accept_unsupported_minor_version
      perl -0pi -e 's/readPcapNg<uint16_t>\(block \+ 14, order\) != 0 \|\|/false ||/' "$source_file"
      ;;
    27)
      name=require_explicit_option_terminator
      perl -0pi -e 's/const size_t optionsEnd = blockLength - 4;\n\t\t\tif \(optionsOffset > optionsEnd\)/const size_t optionsEnd = blockLength - 4;\n\t\t\tconst size_t optionsBegin = optionsOffset;\n\t\t\tif (optionsOffset > optionsEnd)/' "$source_file"
      perl -0pi -e 's/\n\t\t\treturn true;\n\t\t\}\n\n\t\tbool findPcapNgNameResolutionOptions/\n\t\t\treturn optionsOffset == optionsBegin;\n\t\t}\n\n\t\tbool findPcapNgNameResolutionOptions/' "$source_file"
      ;;
    28)
      name=hardcode_tcp_filter
      perl -0pi -e 's/(constexpr uint32_t DecryptionSecrets = 10, DoNotCopyCustom = 0x40000bad;)/$1\n\n\t\tBpfFilterWrapper forcedFilter;\n\t\tif (!forcedFilter.setFilter("tcp"))\n\t\t\treturn false;/' "$source_file"
      perl -0pi -e 's/m_BpfWrapper\.matches\(block \+ 28/forcedFilter.matches(block + 28/' "$source_file"
      perl -0pi -e 's/m_BpfWrapper\.matches\(block \+ 12/forcedFilter.matches(block + 12/' "$source_file"
      ;;
  esac

  if cmp -s "$backup" "$source_file"; then
    printf '%02d %s mutation_applied=0\n' "$mutant" "$name" | tee -a "$results"
    continue
  fi

  docker run --rm --network none -e CMAKE_BUILD_PARALLEL_LEVEL=2 -v "$repo:/src" -w /src "$image" \
    cmake --build build-pcapng-copy-tests --target PcapNgCopyTest --parallel \
    >"/tmp/pcapng-l3-mutant-${mutant}-build.log" 2>&1
  build_rc=$?
  if [[ "$build_rc" -eq 0 ]]; then
    docker run --rm --network none -v "$repo:/src" -w /src "$image" \
      ctest --test-dir build-pcapng-copy-tests --output-on-failure -R '^PcapNgCopy\.' \
      >"/tmp/pcapng-l3-mutant-${mutant}-test.log" 2>&1
    test_rc=$?
  else
    test_rc=not_run
  fi
  printf '%02d %s build=%s focused=%s\n' "$mutant" "$name" "$build_rc" "$test_rc" | tee -a "$results"
done

cp "$backup" "$source_file"
docker run --rm --network none -e CMAKE_BUILD_PARALLEL_LEVEL=2 -v "$repo:/src" -w /src "$image" \
  cmake --build build-pcapng-copy-tests --target PcapNgCopyTest --parallel \
  >/tmp/pcapng-l3-reference-restore-build.log 2>&1
restore_build_rc=$?
docker run --rm --network none -v "$repo:/src" -w /src "$image" \
  ctest --test-dir build-pcapng-copy-tests --output-on-failure -R '^PcapNgCopy\.' \
  >/tmp/pcapng-l3-reference-restore-test.log 2>&1
restore_test_rc=$?
printf 'reference_restore build=%s focused=%s\n' "$restore_build_rc" "$restore_test_rc" | tee -a "$results"

