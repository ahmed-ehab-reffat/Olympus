#!/usr/bin/env bash

set -u

repo=${1:?usage: mutations.sh REFERENCE_TREE BUILD_ROOT [IMAGE]}
build_root=${2:?usage: mutations.sh REFERENCE_TREE BUILD_ROOT [IMAGE]}
image=${3:-olympus-openexr-multipart:final-0811}
source_file="$repo/src/lib/OpenEXRUtil/ImfImageIO.cpp"
header_file="$repo/src/lib/OpenEXRUtil/ImfImageIO.h"
build_dir=/results/build-evaluator
log_root=$(mktemp -d "${TMPDIR:-/tmp}/openexr-mutations.XXXXXX")
original=$(mktemp "${TMPDIR:-/tmp}/openexr-image-io.XXXXXX")
original_header=$(mktemp "${TMPDIR:-/tmp}/openexr-image-io-header.XXXXXX")
cp -p "$source_file" "$original"
cp -p "$header_file" "$original_header"
original_hash=$(sha256sum "$original" | awk '{print $1}')
original_header_hash=$(sha256sum "$original_header" | awk '{print $1}')

restore_source() {
    cp -p "$original" "$source_file"
    cp -p "$original_header" "$header_file"
}

cleanup() {
    restore_source
    rm -f "$original" "$original_header"
}
trap cleanup EXIT

mutate() {
    local name=$1
    case "$name" in
        enable_copy_assignment)
            perl -0pi -e 's/ImagePart& operator= \(const ImagePart&\) = delete;/ImagePart\& operator= (const ImagePart\& other) { header = other.header; return *this; }/' "$header_file"
            ;;
        delete_move_assignment)
            perl -0pi -e 's/ImagePart& operator= \(ImagePart&&\) noexcept = default;/ImagePart\& operator= (ImagePart\&\&) noexcept = delete;/' "$header_file"
            ;;
        load_first_part_only)
            perl -0pi -e 's/for \(int i = 0; i < in\.parts \(\); \+\+i\)/for (int i = 0; i < 1; ++i)/' "$source_file"
            ;;
        load_reverse_order)
            perl -0pi -e 's/for \(int i = 0; i < in\.parts \(\); \+\+i\)/for (int i = in.parts () - 1; i >= 0; --i)/' "$source_file"
            ;;
        save_first_part_only)
            perl -0pi -e 's/for \(size_t i = 0; i < parts\.size \(\); \+\+i\)/for (size_t i = 0; i < 1; ++i)/' "$source_file"
            ;;
        load_flat_mipmap_level_zero_only)
            perl -0pi -e 's/for \(int x = 0; x < img\.numLevels \(\); \+\+x\)\n\s+loadFlatTiledLevel/for (int x = 0; x < 1; ++x)\n                loadFlatTiledLevel/' "$source_file"
            ;;
        load_flat_ripmap_diagonal_only)
            perl -0pi -e 's/for \(int y = 0; y < img\.numYLevels \(\); \+\+y\)\n\s+for \(int x = 0; x < img\.numXLevels \(\); \+\+x\)\n\s+loadFlatTiledLevel \(part, img, x, y\);/for (int x = 0; x < img.numXLevels () \&\& x < img.numYLevels (); ++x)\n                loadFlatTiledLevel (part, img, x, x);/' "$source_file"
            ;;
        load_deep_mipmap_level_zero_only)
            perl -0pi -e 's/for \(int x = 0; x < img\.numLevels \(\); \+\+x\)\n\s+loadDeepTiledLevel/for (int x = 0; x < 1; ++x)\n                loadDeepTiledLevel/' "$source_file"
            ;;
        load_deep_ripmap_diagonal_only)
            perl -0pi -e 's/for \(int y = 0; y < img\.numYLevels \(\); \+\+y\)\n\s+for \(int x = 0; x < img\.numXLevels \(\); \+\+x\)\n\s+loadDeepTiledLevel \(part, img, x, y\);/for (int x = 0; x < img.numXLevels () \&\& x < img.numYLevels (); ++x)\n                loadDeepTiledLevel (part, img, x, x);/' "$source_file"
            ;;
        omit_deep_scanline_sample_counts)
            perl -0pi -e 's/\{\n\s+SampleCountChannel::Edit edit \(level\.sampleCounts \(\)\);\n\s+part\.readPixelSampleCounts \(\n\s+level\.dataWindow \(\)\.min\.y, level\.dataWindow \(\)\.max\.y\);\n\s+\}//' "$source_file"
            ;;
        omit_deep_tiled_sample_counts)
            perl -0pi -e 's/\{\n\s+SampleCountChannel::Edit edit \(level\.sampleCounts \(\)\);\n\s+in\.readPixelSampleCounts \(\n\s+0, in\.numXTiles \(x\) - 1, 0, in\.numYTiles \(y\) - 1, x, y\);\n\s+\}//' "$source_file"
            ;;
        drop_comments_attribute)
            perl -0pi -e 's/if \(strcmp \(i\.name \(\), "channels"\) \&\&/if (strcmp (i.name (), "comments") \&\&\n            strcmp (i.name (), "channels") \&\&/' "$source_file"
            ;;
        retain_stale_header_channels)
            perl -0pi -e 's/if \(strcmp \(i\.name \(\), "channels"\) \&\&\n\s+/if (/' "$source_file"
            ;;
        drop_display_window)
            perl -0pi -e 's/if \(strcmp \(i\.name \(\), "channels"\) \&\&/if (strcmp (i.name (), "displayWindow") \&\&\n            strcmp (i.name (), "channels") \&\&/' "$source_file"
            ;;
        ignore_data_window_source)
            perl -0pi -e 's/hdr\.dataWindow \(\) = dataWindowForFile \(part\.header, img, dws\);/hdr.dataWindow () = img.dataWindow ();/' "$source_file"
            ;;
        ignore_deep_data_window_source)
            perl -0pi -e 's/else if \(const DeepImage\* dimg = dynamic_cast<const DeepImage\*> \(&img\)\)\n\s+\{/else if (const DeepImage* dimg = dynamic_cast<const DeepImage*> (\&img))\n    {\n        hdr.dataWindow () = img.dataWindow ();/' "$source_file"
            ;;
        require_explicit_tiles)
            perl -0pi -e 's/img\.levelMode \(\) != ONE_LEVEL \|\|\s+part\.header\.hasTileDescription \(\)/part.header.hasTileDescription ()/' "$source_file"
            ;;
        force_every_part_tiled)
            perl -0pi -e 's/const bool tiled = img\.levelMode \(\) != ONE_LEVEL \|\|\s+part\.header\.hasTileDescription \(\);/const bool tiled = true;/' "$source_file"
            ;;
        default_explicit_tile_size)
            perl -0pi -e 's/part\.header\.tileDescription \(\)\.xSize,\n\s+part\.header\.tileDescription \(\)\.ySize,/64,\n                64,/' "$source_file"
            ;;
        force_round_down)
            perl -0pi -e 's/img\.levelRoundingMode \(\)/ROUND_DOWN/g' "$source_file"
            ;;
        preserve_invalid_deep_compression)
            perl -0pi -e 's/hdr\.compression \(\) = ZIPS_COMPRESSION;/hdr.compression () = part.header.compression ();/' "$source_file"
            ;;
        omit_uint_channels)
            perl -0pi -e 's/img\.insertChannel \(i\.name \(\), i\.channel \(\)\);/if (strcmp (i.name (), "U"))\n            img.insertChannel (i.name (), i.channel ());/g' "$source_file"
            ;;
        omit_deep_half_framebuffer)
            perl -0pi -e 's/fb\.insert \(i\.name \(\), i\.channel \(\)\.slice \(\)\);/if (i.name () != "A")\n            fb.insert (i.name (), i.channel ().slice ());/g' "$source_file"
            ;;
        reject_single_part_input)
            perl -0pi -e 's/MultiPartInputFile in = openMultipartInput \(fileName\);/MultiPartInputFile in = openMultipartInput (fileName);\n    if (in.parts () == 1) throw ArgExc ("single part rejected");/' "$source_file"
            ;;
        accept_present_empty_name)
            perl -0pi -e 's/if \(!hdr\.hasName \(\) \|\| hdr\.name \(\)\.empty \(\)\)/if (!hdr.hasName ())/g' "$source_file"
            ;;
        allow_multires_header_window)
            perl -0pi -e 's/hdr\.dataWindow \(\) = dataWindowForFile \(part\.header, img, dws\);/hdr.dataWindow () = dataWindowForFile (part.header, img, img.levelMode () == ONE_LEVEL ? dws : USE_IMAGE_DATA_WINDOW);/' "$source_file"
            ;;
        delegate_duplicate_validation)
            perl -0pi -e 's/if \(!names\.insert \(hdr\.name \(\)\)\.second\)\n\s+throw ArgExc \("Image part names must be unique\."\);/names.insert (hdr.name ());/' "$source_file"
            ;;
        stream_silently_accepts_empty)
            perl -0pi -e 's/(saveImages \(OStream& stream, const ImageParts& parts, DataWindowSource dws\)\n\{)/$1\n    if (parts.empty ()) return;/' "$source_file"
            ;;
        stream_silently_accepts_null)
            perl -0pi -e 's/(saveImages \(OStream& stream, const ImageParts& parts, DataWindowSource dws\)\n\{)/$1\n    if (!parts.empty () \&\& !parts[0].image) return;/' "$source_file"
            ;;
        stream_silently_accepts_missing_name)
            perl -0pi -e 's/(saveImages \(OStream& stream, const ImageParts& parts, DataWindowSource dws\)\n\{)/$1\n    if (!parts.empty () \&\& !parts[0].header.hasName ()) return;/' "$source_file"
            ;;
        stream_silently_accepts_empty_name)
            perl -0pi -e 's/(saveImages \(OStream& stream, const ImageParts& parts, DataWindowSource dws\)\n\{)/$1\n    if (!parts.empty () \&\& parts[0].header.hasName () \&\& parts[0].header.name ().empty ()) return;/' "$source_file"
            ;;
        stream_silently_accepts_duplicate)
            perl -0pi -e 's/(saveImages \(OStream& stream, const ImageParts& parts, DataWindowSource dws\)\n\{)/$1\n    if (parts.size () > 1 \&\& parts[0].header.hasName () \&\& parts[1].header.hasName () \&\& parts[0].header.name () == parts[1].header.name ()) return;/' "$source_file"
            ;;
        stream_silently_accepts_unsupported)
            perl -0pi -e 's/(saveImages \(OStream& stream, const ImageParts& parts, DataWindowSource dws\)\n\{)/$1\n    if (!parts.empty () \&\& parts[0].image \&\& !dynamic_cast<const FlatImage*> (parts[0].image.get ()) \&\& !dynamic_cast<const DeepImage*> (parts[0].image.get ())) return;/' "$source_file"
            ;;
        stream_silently_accepts_multires_crop)
            perl -0pi -e 's/(saveImages \(OStream& stream, const ImageParts& parts, DataWindowSource dws\)\n\{)/$1\n    if (dws == USE_HEADER_DATA_WINDOW) for (const ImagePart\& part : parts) if (part.image \&\& part.image->levelMode () != ONE_LEVEL) return;/' "$source_file"
            ;;
        stream_ignores_data_window_source)
            perl -0pi -e 's/(saveImages \(OStream& stream, const ImageParts& parts, DataWindowSource dws\).*?headersForParts \(parts, )dws/${1}USE_IMAGE_DATA_WINDOW/s' "$source_file"
            ;;
        stream_load_first_part_only)
            perl -0pi -e 's/(loadImages \(IStream& stream\).*?)return loadImageParts \(in\);/${1}ImageParts parts;\n    parts.push_back (loadImagePartAt (in, 0));\n    return parts;/s' "$source_file"
            ;;
        stream_load_rejects_single)
            perl -0pi -e 's/(loadImages \(IStream& stream\).*?)(return loadImageParts \(in\);)/${1}if (in.parts () == 1) throw ArgExc ("single stream input rejected");\n    $2/s' "$source_file"
            ;;
        ignore_selected_name)
            perl -0pi -e 's/hdr\.hasName \(\) \&\& hdr\.name \(\) == partName/hdr.hasName ()/' "$source_file"
            ;;
        case_insensitive_selection)
            perl -0pi -e 's/#include <cstring>/#include <cstring>\n#include <strings.h>/' "$source_file"
            perl -0pi -e 's/hdr\.name \(\) == partName/strcasecmp (hdr.name ().c_str (), partName.c_str ()) == 0/' "$source_file"
            ;;
        eager_filename_selection)
            perl -0pi -e 's/(loadImagePart \(const string& fileName, const string& partName\).*?MultiPartInputFile in = openMultipartInput \(fileName\);\n\s+)return loadNamedImagePart \(in, partName\);/${1}ImageParts parts = loadImageParts (in);\n    for (ImagePart\& part : parts)\n        if (part.header.hasName () \&\& part.header.name () == partName)\n            return std::move (part);\n    throw ArgExc ("No image part has the requested name.");/s' "$source_file"
            ;;
        eager_stream_selection)
            perl -0pi -e 's/(loadImagePart \(IStream& stream, const string& partName\).*?)(return loadNamedImagePart \(in, partName\);)/${1}ImageParts parts = loadImageParts (in);\n    for (ImagePart\& part : parts)\n        if (part.header.hasName () \&\& part.header.name () == partName)\n            return std::move (part);\n    throw ArgExc ("No image part has the requested name.");/s' "$source_file"
            ;;
        reject_selected_deep_scanline)
            perl -0pi -e 's/(if \(hdr\.hasName \(\) \&\& hdr\.name \(\) == partName\)\n)/if (hdr.hasType () \&\& hdr.type () == DEEPSCANLINE)\n            throw ArgExc ("selected deep scanline rejected");\n        $1/' "$source_file"
            ;;
        reject_utf8_save_filename)
            perl -0pi -e 's/(saveImages \(\n    const string& fileName, const ImageParts& parts, DataWindowSource dws\)\n\{)/$1\n    for (unsigned char c : fileName)\n        if (c > 127) throw ArgExc ("ASCII filenames only");/' "$source_file"
            ;;
        reject_utf8_load_filename)
            perl -0pi -e 's/(loadImages \(const string& fileName\)\n\{)/$1\n    for (unsigned char c : fileName)\n        if (c > 127) throw ArgExc ("ASCII filenames only");/' "$source_file"
            ;;
        reject_utf8_selected_filename)
            perl -0pi -e 's/(loadImagePart \(const string& fileName, const string& partName\)\n\{)/$1\n    for (unsigned char c : fileName)\n        if (c > 127) throw ArgExc ("ASCII filenames only");/' "$source_file"
            ;;
        abort_on_unsupported_load)
            perl -0pi -e 's/if \(header\.hasType \(\) \&\& isSupportedType \(header\.type \(\)\)\)\n\s+parts\.push_back \(loadImagePartAt \(in, i\)\);/parts.push_back (loadImagePartAt (in, i));/' "$source_file"
            ;;
        rewrite_reverse_order)
            perl -0pi -e 's/for \(int sourcePart = 0; sourcePart < in\.parts \(\); \+\+sourcePart\)/for (int sourcePart = in.parts () - 1; sourcePart >= 0; --sourcePart)/' "$source_file"
            ;;
        rewrite_case_insensitive_names)
            perl -0pi -e 's/#include <cstring>/#include <cstring>\n#include <strings.h>/' "$source_file"
            perl -0pi -e 's/prepared\[i\]\.name \(\) == sourceHeader\.name \(\)/strcasecmp (prepared[i].name ().c_str (), sourceHeader.name ().c_str ()) == 0/' "$source_file"
            ;;
        rewrite_rejects_empty_replacements)
            perl -0pi -e 's/(prepareRewrite \(\n    MultiPartInputFile& in,\n    const ImageParts&   replacements,\n    DataWindowSource    dws\)\n\{)/$1\n    if (replacements.empty ()) throw ArgExc ("empty replacements rejected");/' "$source_file"
            ;;
        rewrite_allows_unmatched_replacement)
            perl -0pi -e 's/for \(bool matched: used\)\n\s+if \(!matched\)\n\s+throw ArgExc \(\n\s+"A replacement name does not match a supported part\."\);/\/\/ unmatched replacements ignored/' "$source_file"
            ;;
        rewrite_matches_unsupported_source_name)
            perl -0pi -e 's/(        const Header& sourceHeader = in\.header \(sourcePart\);\n)/$1        if (sourceHeader.hasType () \&\&\n            !isSupportedType (sourceHeader.type ()))\n            for (size_t i = 0; i < replacements.size (); ++i)\n                if (sourceHeader.hasName () \&\&\n                    prepared[i].name () == sourceHeader.name ())\n                    used[i] = true;\n/' "$source_file"
            ;;
        rewrite_ignores_replacements)
            perl -0pi -e 's/if \(part\.replacement\)/if (false)/' "$source_file"
            ;;
        rewrite_applies_first_replacement_only)
            perl -0pi -e 's/if \(part\.replacement\)/if (part.replacement \&\& std::find_if (plan.begin (), plan.end (), [] (const RewritePart\& candidate) { return candidate.replacement != nullptr; }) == plan.begin () + i)/' "$source_file"
            ;;
        rewrite_allows_same_filename)
            perl -0pi -e 's/    if \(inputFileName == outputFileName\)\n        throw ArgExc \("Input and output image filenames must be different\."\);\n\n//' "$source_file"
            ;;
        rewrite_skips_empty_crop_prevalidation)
            perl -0pi -e 's/        if \(header\.dataWindow \(\)\.min\.x > header\.dataWindow \(\)\.max\.x \|\|\n            header\.dataWindow \(\)\.min\.y > header\.dataWindow \(\)\.max\.y\)\n            throw ArgExc \(\n                "Replacement header and image data windows do not intersect\."\);\n//' "$source_file"
            ;;
        rewrite_normalizes_typeless_single)
            perl -0pi -e 's/if \(flatSingle \&\& !exactHeader\.hasType \(\) \&\& !plan\.front \(\)\.replacement\)/if (false \&\& flatSingle \&\& !exactHeader.hasType () \&\& !plan.front ().replacement)/; s/if \(!flatSingle \|\| exactHeader\.hasType \(\) \|\| plan\.front \(\)\.replacement\)/if (true || !flatSingle || exactHeader.hasType () || plan.front ().replacement)/;' "$source_file"
            ;;
        rewrite_copies_named_typeless_replacement)
            perl -0pi -e 's/ \&\& !plan\.front \(\)\.replacement//; s/ \|\| plan\.front \(\)\.replacement//' "$source_file"
            ;;
        rewrite_drops_replacement_header_state)
            perl -0pi -e 's/outputHeader = prepared\[i\];/outputHeader = prepared[i];\n                outputHeader.erase ("comments");/' "$source_file"
            ;;
        rewrite_decodes_untouched_parts)
            perl -0pi -e 's/else\n\s+copyImagePart \(\n\s+input,\n\s+out,\n\s+part\.sourcePart,\n\s+static_cast<int> \(i\),\n\s+input\.header \(part\.sourcePart\)\.type \(\)\);/else\n        {\n            ImagePart decoded = loadImagePartAt (input, part.sourcePart);\n            writeImagePart (out, static_cast<int> (i), decoded, part.header);\n        }/' "$source_file"
            ;;
        rewrite_aborts_on_unsupported_source)
            perl -0pi -e 's/if \(!sourceHeader\.hasType \(\) \|\| !isSupportedType \(sourceHeader\.type \(\)\)\)\n\s+continue;/if (!sourceHeader.hasType () || !isSupportedType (sourceHeader.type ()))\n            throw ArgExc ("unsupported source part");/' "$source_file"
            ;;
        rewrite_filename_ignores_data_window_source)
            perl -0pi -e 's/(rewriteImages \(\n    const string&.*?prepareRewrite \(input, replacements, )dws/${1}USE_IMAGE_DATA_WINDOW/s' "$source_file"
            ;;
        rewrite_stream_ignores_data_window_source)
            perl -0pi -e 's/(rewriteImages \(\n    IStream&.*?prepareRewrite \(input, replacements, )dws/${1}USE_IMAGE_DATA_WINDOW/s' "$source_file"
            ;;
        reject_utf8_rewrite_input_filename)
            perl -0pi -e 's/(rewriteImages \(\n    const string&     inputFileName,.*?\n\{)/$1\n    for (unsigned char c : inputFileName)\n        if (c > 127) throw ArgExc ("ASCII input filenames only");/s' "$source_file"
            ;;
        reject_utf8_rewrite_output_filename)
            perl -0pi -e 's/(rewriteImages \(\n    const string&     inputFileName,.*?\n\{)/$1\n    for (unsigned char c : outputFileName)\n        if (c > 127) throw ArgExc ("ASCII output filenames only");/s' "$source_file"
            ;;
        stream_load_strict_unknown_type)
            perl -0pi -e 's/(loadImages \(IStream& stream\).*?strictHeaderValidation \()false/${1}true/s' "$source_file"
            ;;
        stream_selection_strict_unknown_type)
            perl -0pi -e 's/(loadImagePart \(IStream& stream, const string& partName\).*?strictHeaderValidation \()false/${1}true/s' "$source_file"
            ;;
        window_filename_ignores_request)
            perl -0pi -e 's/(loadImagePart \(\n    const string& fileName, const string& partName, const Box2i& dataWindow\)\n\{).*?\n\}/$1\n    return loadImagePart (fileName, partName);\n}/s' "$source_file"
            ;;
        window_stream_ignores_request)
            perl -0pi -e 's/(loadImagePart \(IStream& stream, const string& partName, const Box2i& dataWindow\)\n\{).*?\n\}/$1\n    return loadImagePart (stream, partName);\n}/s' "$source_file"
            ;;
        window_reads_all_flat_scanlines)
            perl -0pi -e 's/(loadFlatScanLineWindow \(.*?const Box2i)\s+stagingWindow \(\n        V2i \(header\.dataWindow \(\)\.min\.x, window\.min\.y\),\n        V2i \(header\.dataWindow \(\)\.max\.x, window\.max\.y\)\);/${1} stagingWindow (header.dataWindow ());/s' "$source_file"
            perl -0pi -e 's/(loadFlatScanLineWindow \(.*?part\.readPixels \()window\.min\.y, window\.max\.y/${1}header.dataWindow ().min.y, header.dataWindow ().max.y/s' "$source_file"
            ;;
        window_reads_all_deep_scanlines)
            perl -0pi -e 's/(loadDeepScanLineWindow \(.*?const Box2i)\s+stagingWindow \(\n        V2i \(header\.dataWindow \(\)\.min\.x, window\.min\.y\),\n        V2i \(header\.dataWindow \(\)\.max\.x, window\.max\.y\)\);/${1} stagingWindow (header.dataWindow ());/s' "$source_file"
            perl -0pi -e 's/(loadDeepScanLineWindow \(.*?part\.readPixelSampleCounts \()window\.min\.y, window\.max\.y/${1}header.dataWindow ().min.y, header.dataWindow ().max.y/s' "$source_file"
            perl -0pi -e 's/(loadDeepScanLineWindow \(.*?part\.readPixels \()window\.min\.y, window\.max\.y/${1}header.dataWindow ().min.y, header.dataWindow ().max.y/s' "$source_file"
            ;;
        window_reads_all_flat_tiles)
            perl -0pi -e 's/const Box2i\s+stagingWindow =\n        flatTileStagingWindow \(part, window, dx1, dx2, dy1, dy2\);/dx1 = dy1 = 0;\n    dx2 = part.numXTiles () - 1;\n    dy2 = part.numYTiles () - 1;\n    const Box2i stagingWindow (part.header ().dataWindow ());/' "$source_file"
            ;;
        window_reads_all_deep_tiles)
            perl -0pi -e 's/const Box2i\s+stagingWindow =\n        deepTileStagingWindow \(part, window, dx1, dx2, dy1, dy2\);/dx1 = dy1 = 0;\n    dx2 = part.numXTiles () - 1;\n    dy2 = part.numYTiles () - 1;\n    const Box2i stagingWindow (part.header ().dataWindow ());/' "$source_file"
            ;;
        window_accepts_multiresolution)
            perl -0pi -e 's/    if \(header\.hasTileDescription \(\) &&\n        header\.tileDescription \(\)\.mode != ONE_LEVEL\)\n        throw ArgExc \("Windowed loading requires a ONE_LEVEL image part\."\);\n//' "$source_file"
            ;;
        window_accepts_ripmap)
            perl -0pi -e 's/header\.tileDescription \(\)\.mode != ONE_LEVEL/header.tileDescription ().mode == MIPMAP_LEVELS/' "$source_file"
            ;;
        window_keeps_source_header_window)
            perl -0pi -e 's/    outputHeader\.dataWindow \(\) = window;/    \/\/ data window left unchanged/' "$source_file"
            ;;
        stream_rewrite_strict_unknown_type)
            perl -0pi -e 's/(rewriteImages \(\n    IStream&.*?strictHeaderValidation \()false/${1}true/s' "$source_file"
            ;;
        *)
            echo "unknown mutation: $name" >&2
            return 2
            ;;
    esac
}

run_contract_mutant() {
    local name=$1
    local log="$log_root/$name.log"
    restore_source
    mutate "$name" || return 2
    local mutated_header_hash
    mutated_header_hash=$(sha256sum "$header_file" | awk '{print $1}')
    if [[ "$mutated_header_hash" == "$original_header_hash" ]]; then
        printf '%s\tINVALID-NO-CHANGE\tBuild\n' "$name"
        return
    fi

    if ! docker run --rm --network none --user 10001:10001 \
        -v "$repo:/workspace:ro" -v "$build_root:/results" -w /workspace \
        "$image" cmake --build "$build_dir" \
            --target OpenEXRUtil --parallel 2 >"$log" 2>&1; then
        printf '%s\tINVALID-PRODUCTION-COMPILE\tBuild\n' "$name"
        return
    fi

    if ! docker run --rm --network none --user 10001:10001 \
        -v "$repo:/workspace:ro" -v "$build_root:/results" -w /workspace \
        "$image" cmake --build "$build_dir" \
            --target OpenEXRUtilMultipartTest --parallel 2 >>"$log" 2>&1; then
        printf '%s\tKILLED\tBuild\n' "$name"
        return
    fi

    printf '%s\tSURVIVED-FOCUSED\tBuild\n' "$name"
}

run_mutant() {
    local name=$1
    local test_name=$2
    local log="$log_root/$name.log"
    restore_source
    mutate "$name" || return 2
    local mutated_hash
    mutated_hash=$(sha256sum "$source_file" | awk '{print $1}')
    if [[ "$mutated_hash" == "$original_hash" ]]; then
        printf '%s\tINVALID-NO-CHANGE\t%s\n' "$name" "$test_name"
        return
    fi

    if ! docker run --rm --network none --user 10001:10001 \
        -v "$repo:/workspace:ro" -v "$build_root:/results" -w /workspace \
        "$image" cmake --build "$build_dir" \
            --target OpenEXRUtilMultipartTest --parallel 2 >"$log" 2>&1; then
        printf '%s\tINVALID-COMPILE\t%s\n' "$name" "$test_name"
        return
    fi

    if ! docker run --rm --network none --user 10001:10001 \
        -v "$repo:/workspace:ro" -v "$build_root:/results" -w /workspace \
        "$image" ctest --test-dir "$build_dir" --output-on-failure \
            -R "^OpenEXRUtilMultipart\\.${test_name}$" >>"$log" 2>&1; then
        printf '%s\tKILLED\t%s\n' "$name" "$test_name"
        return
    fi

    if ! docker run --rm --network none --user 10001:10001 \
        -v "$repo:/workspace:ro" -v "$build_root:/results" -w /workspace \
        "$image" ctest --test-dir "$build_dir" --output-on-failure \
            -R '^OpenEXRUtilMultipart\.' >>"$log" 2>&1; then
        printf '%s\tKILLED-BY-OTHER-FOCUSED\t%s\n' "$name" "$test_name"
        return
    fi

    printf '%s\tSURVIVED-FOCUSED\t%s\n' "$name" "$test_name"
}

printf 'mutation\tresult\ttarget\n'
run_contract_mutant enable_copy_assignment
run_contract_mutant delete_move_assignment
run_mutant load_first_part_only LoadHeterogeneous
run_mutant load_reverse_order LoadHeterogeneous
run_mutant save_first_part_only SaveHeterogeneous
run_mutant load_flat_mipmap_level_zero_only LoadHeterogeneous
run_mutant load_flat_ripmap_diagonal_only LoadHeterogeneous
run_mutant load_deep_mipmap_level_zero_only LoadHeterogeneous
run_mutant load_deep_ripmap_diagonal_only LoadHeterogeneous
run_mutant omit_deep_scanline_sample_counts LoadHeterogeneous
run_mutant omit_deep_tiled_sample_counts LoadHeterogeneous
run_mutant drop_comments_attribute HeaderAndCrop
run_mutant retain_stale_header_channels HeaderAndCrop
run_mutant drop_display_window SaveHeterogeneous
run_mutant ignore_data_window_source HeaderAndCrop
run_mutant ignore_deep_data_window_source HeaderAndCrop
run_mutant require_explicit_tiles SaveHeterogeneous
run_mutant force_every_part_tiled SaveHeterogeneous
run_mutant default_explicit_tile_size HeaderAndCrop
run_mutant force_round_down SaveHeterogeneous
run_mutant preserve_invalid_deep_compression SaveHeterogeneous
run_mutant omit_uint_channels LoadHeterogeneous
run_mutant omit_deep_half_framebuffer LoadHeterogeneous
run_mutant reject_single_part_input SinglePartLoad
run_mutant accept_present_empty_name ApiAndValidation
run_mutant allow_multires_header_window ApiAndValidation
run_mutant delegate_duplicate_validation ApiAndValidation
run_mutant stream_silently_accepts_empty ApiAndValidation
run_mutant stream_silently_accepts_null ApiAndValidation
run_mutant stream_silently_accepts_missing_name ApiAndValidation
run_mutant stream_silently_accepts_empty_name ApiAndValidation
run_mutant stream_silently_accepts_duplicate ApiAndValidation
run_mutant stream_silently_accepts_unsupported ApiAndValidation
run_mutant stream_silently_accepts_multires_crop ApiAndValidation
run_mutant stream_ignores_data_window_source StreamRoundTrip
run_mutant stream_load_first_part_only StreamRoundTrip
run_mutant stream_load_rejects_single StreamRoundTrip
run_mutant ignore_selected_name SelectiveLoad
run_mutant case_insensitive_selection SelectiveLoad
run_mutant eager_filename_selection SelectiveLoad
run_mutant eager_stream_selection SelectiveLoad
run_mutant reject_selected_deep_scanline StreamRoundTrip
run_mutant reject_utf8_save_filename Utf8Filename
run_mutant reject_utf8_load_filename Utf8Filename
run_mutant reject_utf8_selected_filename Utf8Filename
run_mutant abort_on_unsupported_load UnsupportedParts
run_mutant rewrite_reverse_order RewriteParts
run_mutant rewrite_case_insensitive_names RewriteValidation
run_mutant rewrite_rejects_empty_replacements RewriteParts
run_mutant rewrite_allows_unmatched_replacement RewriteValidation
run_mutant rewrite_matches_unsupported_source_name RewriteValidation
run_mutant rewrite_ignores_replacements RewriteParts
run_mutant rewrite_applies_first_replacement_only RewriteParts
run_mutant rewrite_allows_same_filename RewriteValidation
run_mutant rewrite_skips_empty_crop_prevalidation RewriteValidation
run_mutant rewrite_normalizes_typeless_single SinglePartLoad
run_mutant rewrite_copies_named_typeless_replacement SinglePartLoad
run_mutant rewrite_drops_replacement_header_state RewriteParts
run_mutant rewrite_decodes_untouched_parts RewriteParts
run_mutant rewrite_aborts_on_unsupported_source UnsupportedParts
run_mutant rewrite_filename_ignores_data_window_source RewriteParts
run_mutant rewrite_stream_ignores_data_window_source RewriteParts
run_mutant reject_utf8_rewrite_input_filename Utf8Filename
run_mutant reject_utf8_rewrite_output_filename Utf8Filename
run_mutant stream_load_strict_unknown_type UnsupportedParts
run_mutant stream_selection_strict_unknown_type UnsupportedParts
run_mutant stream_rewrite_strict_unknown_type UnsupportedParts
run_mutant window_filename_ignores_request WindowedLoad
run_mutant window_stream_ignores_request WindowedLoad
run_mutant window_reads_all_flat_scanlines WindowedLoad
run_mutant window_reads_all_deep_scanlines WindowedLoad
run_mutant window_reads_all_flat_tiles WindowedLoad
run_mutant window_reads_all_deep_tiles WindowedLoad
run_mutant window_accepts_multiresolution WindowedLoad
run_mutant window_accepts_ripmap WindowedLoad
run_mutant window_keeps_source_header_window WindowedLoad

restore_source
restored_hash=$(sha256sum "$source_file" | awk '{print $1}')
restored_header_hash=$(sha256sum "$header_file" | awk '{print $1}')
[[ "$restored_hash" == "$original_hash" && \
   "$restored_header_hash" == "$original_header_hash" ]] || {
    echo "reference sources were not restored" >&2
    exit 3
}
printf 'logs\t%s\t-\n' "$log_root"
