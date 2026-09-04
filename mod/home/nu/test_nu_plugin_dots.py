#!/usr/bin/env python3
"""Tests for mod/home/nu/nu_plugin_dots.py (nushell plugin: lon/lat dots on a basemap -> SVG).

Run with: python3 mod/home/nu/test_nu_plugin_dots.py
"""
import importlib.util
import json
import os
import subprocess
import sys
import types

TOOLS = os.path.dirname(os.path.abspath(__file__))
PLUGIN = os.path.join(TOOLS, "nu_plugin_dots.py")


def load_plugin():
    spec = importlib.util.spec_from_file_location("nu_plugin_dots", PLUGIN)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def read_line(f):
    line = f.readline()
    assert line, "unexpected EOF"
    return line


def test_handshake_subprocess():
    """Byte-level handshake: \x04json header, then Hello line (what the engine reads)."""
    proc = subprocess.Popen(
        [sys.executable, PLUGIN, "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    header = proc.stdout.read(5)
    assert header == b"\x04json", f"bad encoding header: {header!r}"
    first = read_line(proc.stdout)
    hello = json.loads(first)
    assert "Hello" in hello, f"first message must be Hello, got {first!r}"
    info = hello["Hello"]
    assert info["protocol"] == "nu-plugin"
    assert info["version"].startswith("0.115"), info["version"]

    # respond with our own hello, ask for the signature, then close
    proc.stdin.write(json.dumps({"Hello": info}).encode() + b"\n")
    proc.stdin.write(json.dumps({"Call": [1, {"Signature": null()}]}).encode() + b"\n")
    proc.stdin.flush()
    line = read_line(proc.stdout)
    resp = json.loads(line)
    assert "CallResponse" in resp, f"expected CallResponse, got {line!r}"
    call_id, response = resp["CallResponse"]
    assert call_id == 1
    assert "Signature" in response
    sigs = response["Signature"]
    assert len(sigs) == 1
    assert sigs[0]["sig"]["name"] == "dots"

    proc.stdin.close()
    proc.wait(timeout=10)
    assert proc.returncode == 0, f"exit code {proc.returncode}, stderr: {proc.stderr.read()!r}"


def null():
    return None


class FakeRenderer:
    def __init__(self):
        self.calls = []

    def __call__(self, points, source):
        self.calls.append((points, source))
        return "<svg>fake-map</svg>"


def run_protocol(plugin, lines, renderer=None):
    """Feed protocol lines through plugin_loop in-process, collect output lines."""
    outs = []
    if renderer is not None:
        original = plugin.render_svg
        plugin.render_svg = renderer
    try:
        plugin.plugin_loop(iter(lines), lambda obj: outs.append(obj))
    finally:
        if renderer is not None:
            plugin.render_svg = original
    return outs


def rec(lon, lat):
    return {
        "Record": {
            "val": {
                "lon": {"Int": {"val": lon, "span": SPAN}},
                "lat": {"Float": {"val": lat, "span": SPAN}},
            },
            "span": SPAN,
        }
    }


SPAN = {"start": 0, "end": 100}
ENGINE_HELLO = {"Hello": {"protocol": "nu-plugin", "version": "0.115.0", "features": []}}


def test_signature_and_metadata():
    plugin = load_plugin()
    outs = run_protocol(
        plugin,
        [
            json.dumps(ENGINE_HELLO),
            json.dumps({"Call": [0, {"Signature": None}]}),
            json.dumps({"Call": [1, {"Metadata": None}]}),
            json.dumps({"Goodbye": None}),
        ],
    )
    assert len(outs) == 2
    sig_resp = outs[0]["CallResponse"]
    assert sig_resp[0] == 0
    sig = sig_resp[1]["Signature"][0]["sig"]
    assert sig["name"] == "dots"
    source_flags = [n for n in sig["named"] if n["long"] == "source"]
    assert len(source_flags) == 1

    meta_resp = outs[1]["CallResponse"]
    assert meta_resp[0] == 1
    assert "version" in meta_resp[1]["Metadata"]


def test_run_with_value_input():
    plugin = load_plugin()
    renderer = FakeRenderer()
    call = {
        "Call": [
            7,
            {
                "Run": {
                    "name": "dots",
                    "call": {
                        "head": SPAN,
                        "positional": [],
                        "named": [
                            [{"item": "source", "span": SPAN}, {"String": {"val": "a.b.c", "span": SPAN}}]
                        ],
                    },
                    "input": {
                        "Value": [
                            {"List": {"vals": [rec(101, 51.5), rec(20, -33.9)], "span": SPAN}},
                            None,
                        ]
                    },
                }
            },
        ]
    }
    outs = run_protocol(plugin, [json.dumps(ENGINE_HELLO), json.dumps(call)], renderer)
    assert len(outs) == 1
    cid, response = outs[0]["CallResponse"]
    assert cid == 7
    header = response["PipelineData"]
    assert "Value" in header, f"expected a value response, got {header!r}"
    value, _ = header["Value"]
    assert "String" in value, value
    assert value["String"]["val"] == "<svg>fake-map</svg>"
    (points, source), = renderer.calls
    assert source == "a.b.c"
    assert points == [
        {"lon": 101, "lat": 51.5},
        {"lon": 20, "lat": -33.9},
    ]


def test_run_default_source():
    plugin = load_plugin()
    renderer = FakeRenderer()
    call = {
        "Call": [
            8,
            {
                "Run": {
                    "name": "dots",
                    "call": {"head": SPAN, "positional": [], "named": []},
                    "input": {"Value": [{"List": {"vals": [rec(0, 0)], "span": SPAN}}, None]},
                }
            },
        ]
    }
    run_protocol(plugin, [json.dumps(ENGINE_HELLO), json.dumps(call)], renderer)
    (points, source), = renderer.calls
    assert source == "Esri.WorldGrayCanvas"


def test_run_with_list_stream_input():
    plugin = load_plugin()
    renderer = FakeRenderer()
    lines = [
        json.dumps(ENGINE_HELLO),
        json.dumps(
            {
                "Call": [
                    9,
                    {
                        "Run": {
                            "name": "dots",
                            "call": {"head": SPAN, "positional": [], "named": []},
                            "input": {"ListStream": {"id": 3, "span": SPAN, "metadata": None}},
                        }
                    },
                ]
            }
        ),
        json.dumps({"Data": [3, {"List": rec(1, 2)}]}),
        json.dumps({"Data": [3, {"List": rec(3, 4)}]}),
        json.dumps({"End": 3}),
    ]
    outs = run_protocol(plugin, lines, renderer)
    assert len(outs) == 1
    cid, response = outs[0]["CallResponse"]
    assert cid == 9
    (points, _), = renderer.calls
    assert points == [{"lon": 1, "lat": 2}, {"lon": 3, "lat": 4}]


def test_run_error_on_bad_input():
    plugin = load_plugin()
    call = {
        "Call": [
            10,
            {
                "Run": {
                    "name": "dots",
                    "call": {"head": SPAN, "positional": [], "named": []},
                    "input": {"Value": [{"List": {"vals": [{"Int": {"val": 1, "span": SPAN}}], "span": SPAN}}, None]},
                }
            },
        ]
    }
    outs = run_protocol(plugin, [json.dumps(ENGINE_HELLO), json.dumps(call)])
    assert len(outs) == 1
    cid, response = outs[0]["CallResponse"]
    assert cid == 10
    assert "Error" in response, f"expected Error, got {response!r}"


def test_render_svg_calls_contextily():
    plugin = load_plugin()

    class FakeAxes:
        def __init__(self):
            self.scatter_calls = []

        def scatter(self, *args, **kwargs):
            self.scatter_calls.append((args, kwargs))

    class FakeFigure:
        def __init__(self, ax):
            self.ax = ax

        def savefig(self, buf, format=None):
            buf.write(b"<svg>real-fake</svg>")

        def close(self):
            pass

    calls = {}

    class FakeCtx:
        @staticmethod
        def add_basemap(ax, **kwargs):
            calls["basemap"] = kwargs

    pyplot = types.ModuleType("matplotlib.pyplot")
    fig, ax = FakeFigure(None), FakeAxes()
    pyplot.subplots = lambda **kwargs: (fig, ax)
    pyplot.close = lambda f: None
    matplotlib = types.ModuleType("matplotlib")
    matplotlib.use = lambda backend: None
    matplotlib.pyplot = pyplot
    sys.modules["matplotlib"] = matplotlib
    sys.modules["matplotlib.pyplot"] = pyplot
    sys.modules["contextily"] = FakeCtx()

    try:
        svg = plugin.render_svg(
            [{"lon": -122.4, "lat": 37.7}, {"lon": -122.3, "lat": 37.8}],
            "Esri.WorldGrayCanvas",
        )
    finally:
        del sys.modules["matplotlib"], sys.modules["matplotlib.pyplot"], sys.modules["contextily"]

    assert svg == "<svg>real-fake</svg>"
    assert calls["basemap"]["source"] == "Esri.WorldGrayCanvas"
    assert calls["basemap"]["crs"] == 4326
    extent = calls["basemap"]["extent"]
    # points are inside the extent
    assert extent[0] < -122.4 < extent[2]
    assert extent[1] < 37.7 < extent[3]
    (args, kwargs), = ax.scatter_calls
    assert sorted(args[0]) == [-122.4, -122.3]
    assert sorted(args[1]) == [37.7, 37.8]


def test_render_svg_single_point_extent():
    plugin = load_plugin()

    class FakeAxes:
        def scatter(self, *args, **kwargs):
            pass

    class FakeFigure:
        def savefig(self, buf, format=None):
            buf.write(b"<svg/>")

    calls = {}

    class FakeCtx:
        @staticmethod
        def add_basemap(ax, **kwargs):
            calls["basemap"] = kwargs

    pyplot = types.ModuleType("matplotlib.pyplot")
    pyplot.subplots = lambda **kwargs: (FakeFigure(), FakeAxes())
    pyplot.close = lambda f: None
    matplotlib = types.ModuleType("matplotlib")
    matplotlib.use = lambda backend: None
    matplotlib.pyplot = pyplot
    sys.modules["matplotlib"] = matplotlib
    sys.modules["matplotlib.pyplot"] = pyplot
    sys.modules["contextily"] = FakeCtx()

    try:
        plugin.render_svg([{"lon": 5, "lat": 6}], "Esri.WorldGrayCanvas")
    finally:
        del sys.modules["matplotlib"], sys.modules["matplotlib.pyplot"], sys.modules["contextily"]

    extent = calls["basemap"]["extent"]
    assert extent[0] < 5 < extent[2]
    assert extent[1] < 6 < extent[3]


TESTS = [
    test_handshake_subprocess,
    test_signature_and_metadata,
    test_run_with_value_input,
    test_run_default_source,
    test_run_with_list_stream_input,
    test_run_error_on_bad_input,
    test_render_svg_calls_contextily,
    test_render_svg_single_point_extent,
]


def main():
    failed = 0
    for test in TESTS:
        try:
            test()
            print(f"ok   {test.__name__}")
        except AssertionError as e:
            failed += 1
            print(f"FAIL {test.__name__}: {e}")
        except Exception as e:
            failed += 1
            print(f"ERROR {test.__name__}: {type(e).__name__}: {e}")
    if failed:
        sys.exit(1)
    print(f"\n{len(TESTS)} tests passed")


if __name__ == "__main__":
    main()
