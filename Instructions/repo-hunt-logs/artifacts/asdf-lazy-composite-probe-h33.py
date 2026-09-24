import io, sys, contextlib
import numpy as np
import asdf
from asdf.extension import Converter, Extension

CALLS = {"from": 0, "to": 0}

class Point:
    def __init__(self, x, y, arr=None):
        self.x, self.y, self.arr = x, y, arr

class PointConverter(Converter):
    tags = ["asdf://h33.test/tags/point-1.*"]
    types = [Point]
    lazy = False
    def to_yaml_tree(self, obj, tag, ctx):
        CALLS["to"] += 1
        d = {"x": obj.x, "y": obj.y}
        if obj.arr is not None:
            d["arr"] = obj.arr
        return d
    def select_tag(self, obj, tags, ctx):
        return sorted(tags)[-1]
    def from_yaml_tree(self, node, tag, ctx):
        CALLS["from"] += 1
        return Point(node["x"], node["y"], node.get("arr"))

def make_ext(write_version):
    tags = ["asdf://h33.test/tags/point-1.1.0", "asdf://h33.test/tags/point-1.0.0"] if write_version == "1.1.0" else ["asdf://h33.test/tags/point-1.0.0"]
    class Ext(Extension):
        extension_uri = f"asdf://h33.test/extensions/pt-{write_version}"
        converters = [PointConverter()]
    Ext.tags = tags
    return Ext()

def build(path):
    with asdf.config_context() as cfg:
        cfg.add_extension(make_ext("1.0.0"))
        af = asdf.AsdfFile({"a": Point(1, 2, np.arange(5.0)), "b": np.arange(3), "c": {"p": Point(3, 4)}, "d": [1, 2, 3]})
        af.write_to(path)

def reset():
    CALLS["from"] = CALLS["to"] = 0

def main(tmp):
    src, dst = f"{tmp}/src.asdf", f"{tmp}/dst.asdf"
    build(src)
    with asdf.config_context() as cfg:
        cfg.add_extension(make_ext("1.1.0"))
        # P1: pass-through write
        reset()
        with asdf.open(src, lazy_tree=True) as af:
            af["d"] = [9]
            af.write_to(dst)
        raw = open(dst, "rb").read().decode("latin1")
        print("P1 converter from/to:", CALLS["from"], CALLS["to"], "| tag 1.0.0 kept:", "point-1.0.0" in raw, "| 1.1.0:", "point-1.1.0" in raw)
        with asdf.open(dst, lazy_tree=False) as af2:
            print("   reread a.arr:", list(af2["a"].arr), "b:", list(af2["b"]), "c.p.x:", af2["c"]["p"].x, "d:", list(af2["d"]))
        # P2: info must not convert, and write after info still passes through
        reset()
        with asdf.open(src, lazy_tree=True) as af:
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                af.info(max_rows=None)
            print("P2 info converter calls:", CALLS["from"])
            print("   " + buf.getvalue().replace("\n", "\n   "))
            af.write_to(dst)
        raw = open(dst, "rb").read().decode("latin1")
        print("   after info write: tag 1.0.0 kept:", "point-1.0.0" in raw, "calls", CALLS["from"])
        # P3: search paths without conversion
        reset()
        with asdf.open(src, lazy_tree=True) as af:
            r = af.search(type_=Point)
            print("P3 search paths:", r.paths, "calls:", CALLS["from"])
            r2 = af.search(key="x")
            print("   key=x paths:", r2.paths, "calls:", CALLS["from"])
            print("   node conversion on demand:", type(af.search(key="^p$").node).__name__, "calls:", CALLS["from"])

if __name__ == "__main__":
    main(sys.argv[1])

def probe_update(tmp):
    import shutil
    src = f"{tmp}/src.asdf"; upd = f"{tmp}/upd.asdf"
    build(src); shutil.copy(src, upd)
    with asdf.config_context() as cfg:
        cfg.add_extension(make_ext("1.1.0"))
        reset()
        with asdf.open(upd, mode="rw", lazy_tree=True) as af:
            af["e"] = np.arange(7) * 10
            af["d"] = [7]
            af.update()
            print("P4 update calls:", CALLS["from"], "| a.arr after update:", list(af["a"].arr), "b:", list(af["b"]))
        with asdf.open(upd, lazy_tree=False) as af2:
            print("   reread:", list(af2["a"].arr), list(af2["b"]), list(af2["e"]), af2["c"]["p"].y)
        raw = open(upd, "rb").read().decode("latin1")
        print("   tag kept:", "point-1.0.0" in raw)
        # version change forces conversion
        reset()
        with asdf.open(src, lazy_tree=True) as af:
            af.write_to(f"{tmp}/v.asdf", version="1.5.0")
        print("P5 version change calls:", CALLS["from"], "| retag:", "point-1.1.0" in open(f"{tmp}/v.asdf","rb").read().decode("latin1"))
        with asdf.open(src, lazy_tree=True) as af:
            print("P6 schema_info a:", af.schema_info("title"))

if __name__ == "__main__" and len(sys.argv) > 2:
    probe_update(sys.argv[1])
