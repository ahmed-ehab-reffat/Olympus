# Repository map

Repository pin: `node-opcua/node-opcua@e233d906138995583f42359831d1908e3cb005e7`.

| Path | Role in this task |
|---|---|
| `packages/node-opcua-address-space/src/nodeset_tools/nodeset_to_xml.ts` | public exporter, model declarations, namespace translation, aliases, node/type/value serialization, and reference filtering |
| `packages/node-opcua-address-space/source/index.ts` | declaration entry point advertised by `package.json#types` |
| `packages/node-opcua-address-space/src/nodeset_tools/construct_namespace_dependency.ts` | existing model-dependency and priority computation reused by the new export |
| `packages/node-opcua-address-space/source/xml_writer.ts` | shared serializer state carrying the selected namespace-index set |
| `packages/node-opcua-address-space/source/loader/` | established fresh-address-space NodeSet loading and semantic round-trip oracle |
| `packages/node-opcua-address-space/test/test_loadnodeset_value.ts` | pre-existing `LNEX5` and `LNEX8` compatibility cases |
| `packages/node-opcua-address-space/test/nodeset_tools/test_export_selected_namespaces.36c2ba.test.ts` | thirteen black-box feature/API checks injected at an unpredictable additive path by `test.patch` |
| `test.sh` | offline evaluator entry point and JUnit producer injected by `test.patch` |

The production solution changes the exporter, declaration entry point, and XML
writer paths. That layout is
an implementation record, not a participant requirement.
