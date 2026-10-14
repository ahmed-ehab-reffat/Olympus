---
Repository: https://github.com/bufbuild/protobuf-es
Issue: N/A
Commit: c3a71a8679b06b07a4ebb3bd6f5b02d68759a179
Language: TypeScript
Category: feature-request
Title: Add a Protobuf source printer to protoplugin
---

# Add a Protobuf source printer to protoplugin

Plugins built on `@bufbuild/protoplugin` can read a file descriptor, but there is no way to turn one back into `.proto` source. We'd like a new export, `getProtoSource(file, options?)`, that takes a `DescFile` and returns the text of a Protobuf source file for it.

The text has to be faithful. If we compile it with protoc under the same file name, next to the same imported files, we should get back the same `FileDescriptorProto` we started from, and only the source code info is allowed to differ. That has to hold for proto2, proto3 and editions 2023 and 2024 files, and for everything those files can declare.

Comments matter too. After that compile, every element that `getComments` can describe should report the same leading, trailing and detached comments as before. The input files only ever use `//` comments.

Custom options are kept on the descriptor as unknown fields, so they have to be decoded. When the caller passes `options.registry`, that is where we look up their extensions; otherwise we use the file and the files it imports. You can assume every option in the file can be found that way.
