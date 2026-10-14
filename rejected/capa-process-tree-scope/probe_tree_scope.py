import textwrap
import capa.rules, capa.capabilities.dynamic as dyn, capa.loader
import capa.features.extractors.null as null
from capa.features.address import ProcessAddress, ThreadAddress, DynamicCallAddress
from capa.features.insn import API
from capa.features.common import OS, Arch, Format
import capa.render.result_document as rd, capa.render.verbose as v, capa.render.vverbose as vv

def proc(ppid, pid, apis):
    pa = ProcessAddress(pid=pid, ppid=ppid); ta = ThreadAddress(pa, tid=1)
    calls = {DynamicCallAddress(ta, i): null.CallFeatures(name=a, features=[(DynamicCallAddress(ta, i), API(a))]) for i, a in enumerate(apis)}
    return pa, null.ProcessFeatures(features=[], threads={ta: null.ThreadFeatures(features=[], calls=calls)}, name=f"p{pid}")

procs = dict([proc(0, 100, ["CreateProcess"]), proc(100, 200, ["WriteFile"]), proc(200, 300, ["RegSetValue"]), proc(0, 400, ["WriteFile"])])
ext = null.NullDynamicFeatureExtractor(base_address=None, sample_hashes=None, global_features=[], file_features=[], processes=procs)
def r(s): return capa.rules.Rule.from_yaml(textwrap.dedent(s))
rules = capa.rules.RuleSet([
 r("""
 rule:
   meta: {name: writes and persists, scopes: {static: unsupported, dynamic: process tree}}
   features:
     - and:
       - api: WriteFile
       - api: RegSetValue
 """),
 r("""
 rule:
   meta: {name: spawner of persister, scopes: {static: unsupported, dynamic: process tree}}
   features:
     - and:
       - api: CreateProcess
       - match: writes and persists
 """),
 r("""
 rule:
   meta: {name: file sees tree, scopes: {static: unsupported, dynamic: file}}
   features:
     - match: writes and persists
 """),
])
caps = dyn.find_dynamic_capabilities(rules, ext, disable_progress=True)
for k, vals in caps.matches.items(): print(k, [a for a, _ in vals])
print("counts", caps.feature_counts)
p = list(ext.get_processes())[0]; t = list(ext.get_threads(p))[0]; c = list(ext.get_calls(p, t))[0]
print(list(ext.extract_call_features(p, t, c)))
meta = rd.Metadata.model_construct if False else None
import capa.loader as L
layout = L.compute_dynamic_layout(rules, ext, caps.matches)
print("layout", [p.address.value for p in layout.processes])
