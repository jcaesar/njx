#!/usr/bin/env python3
"""Nushell plugin: plot
Subcommand `plot dots`: input a list of lon/lat records, output SVG map
with contextily basemap.
Records may carry an optional `category` string; each category gets its
own color in the plot and an entry in the legend.
Subcommand `plot lines`: input a list of numbers, a record of lists of
numbers (key = label), or a list of records with `x`/`y` and optional
`category`; output SVG line plot.
"""
import io
import json
import sys

PLUGIN_VERSION = "0.1.0"
NUSHELL_VERSION = "0.116.0"
DEFAULT_SOURCE = "Esri.WorldGrayCanvas"

def signatures():
    return {
        "Signature": [
            {
                "sig": {
                    "name": "plot dots",
                    "description": "Plot lon/lat points on a map and output SVG; records may carry an optional 'category' string for color-coded legend entries",
                    "extra_description": "",
                    "required_positional": [],
                    "optional_positional": [],
                    "rest_positional": None,
                    "named": [
                        {
                            "long": "source",
                            "short": None,
                            "arg": "String",
                            "required": False,
                            "desc": "Map source for contextily"
                        },
                        {
                            "long": "no-basemap",
                            "short": None,
                            "arg": "Boolean",
                            "required": False,
                            "desc": "Skip the contextily basemap (no network needed)"
                        }
                    ],
                    "input_output_types": [["Any", "Any"]],
                    "allow_variants_without_examples": True,
                    "search_terms": [],
                    "is_filter": True,
                    "creates_scope": False,
                    "allows_unknown_args": False,
                    "category": "Experimental",
                },
                "examples": [],
            },
            {
                "sig": {
                    "name": "plot lines",
                    "description": "Make line plots and output SVG; input a list of numbers, a record of lists of numbers (key = label), or a list of records with 'x'/'y' and optional 'category'",
                    "extra_description": "",
                    "required_positional": [],
                    "optional_positional": [],
                    "rest_positional": None,
                    "named": [],
                    "input_output_types": [["Any", "Any"]],
                    "allow_variants_without_examples": True,
                    "search_terms": [],
                    "is_filter": True,
                    "creates_scope": False,
                    "allows_unknown_args": False,
                    "category": "Experimental",
                },
                "examples": [],
            }
        ]
    }

def extract_value(node):
    if node is None:
        return None
    if "Float" in node:
        return node["Float"]["val"]
    if "Int" in node:
        return node["Int"]["val"]
    if "String" in node:
        return node["String"]["val"]
    if "Bool" in node:
        return node["Bool"]["val"]
    if "Nothing" in node:
        return None
    if "List" in node:
        return [extract_value(v) for v in node["List"]["vals"]]
    if "Record" in node:
        return {k: extract_value(c) for k, c in node["Record"]["val"].items()}
    raise ValueError(f"unsupported value type: {list(node)}")

def is_number(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)

def extract_points_from_records(vals):
    points = []
    for rec in vals:
        if not isinstance(rec, dict) or "lon" not in rec or "lat" not in rec:
            raise ValueError("missing lon/lat")
        if not is_number(rec["lon"]) or not is_number(rec["lat"]):
            raise ValueError("lon/lat must be numbers")
        category = rec.get("category")
        if category is not None and not isinstance(category, str):
            raise ValueError("category not a string")
        points.append({"lon": float(rec["lon"]), "lat": float(rec["lat"]), "category": category})
    return points

def fig_to_svg(fig):
    import matplotlib.pyplot as plt

    buf = io.BytesIO()
    fig.savefig(buf, format="svg")
    plt.close(fig)
    return buf.getvalue().decode("utf-8")

def render_svg(points, source, no_basemap=False):
    import geopandas as gpd
    import matplotlib
    import matplotlib.pyplot as plt
    from shapely.geometry import Point

    matplotlib.use("Agg")

    fig, ax = plt.subplots(figsize=(16,16))
    crs = 4326

    categories = list(dict.fromkeys(p["category"] or "uncategorized" for p in points))
    cmap = plt.get_cmap("tab10")
    for i, cat in enumerate(categories):
        pts = [p for p in points if (p["category"] or "uncategorized") == cat]
        geometry = [Point(p["lon"], p["lat"]) for p in pts]
        gpd.GeoDataFrame(geometry=geometry, crs=crs).plot(
            ax=ax, color=cmap(i % 10), label=cat)
    if any(p["category"] is not None for p in points):
        ax.legend()

    if not no_basemap:
        import contextily as ctx
        ctx.add_basemap(ax, source=source, crs=crs)

    return fig_to_svg(fig)

def lines_from_value(value):
    if isinstance(value, list):
        if value and all(is_number(v) for v in value):
            return [("values", [(i, float(v)) for i, v in enumerate(value)])]
        if value and all(isinstance(v, dict) and "x" in v and "y" in v for v in value):
            groups = {}
            for rec in value:
                label = rec.get("category")
                if label is None:
                    label = "points"
                if not isinstance(label, str):
                    raise TypeError("category must be a string")
                if not is_number(rec["x"]) or not is_number(rec["y"]):
                    raise TypeError("x/y must be numbers")
                groups.setdefault(label, []).append((float(rec["x"]), float(rec["y"])))
            return list(groups.items())
        raise ValueError("list input must be numbers or records with 'x' and 'y'")
    if isinstance(value, dict):
        if not value:
            raise ValueError("record input has no lines to plot")
        lines = []
        for key, vals in value.items():
            if not isinstance(vals, list) or not vals or not all(is_number(v) for v in vals):
                raise ValueError(f"'{key}' must be a non-empty list of numbers")
            lines.append((key, [(i, float(v)) for i, v in enumerate(vals)]))
        return lines
    raise ValueError(
        "expected a list of numbers, a record of lists of numbers, or a list of records with 'x'/'y'"
    )

def render_lines_svg(lines):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(16, 8))
    for label, pts in lines:
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        ax.plot(xs, ys, label=label)
    if len(lines) > 1:
        ax.legend()
    return fig_to_svg(fig)

def extract_rows(item):
    if "List" in item:
        inner = item["List"]
        if isinstance(inner, dict) and "vals" in inner:
            return [extract_value(v) for v in inner["vals"]]
        return [extract_value(inner)]
    value = extract_value(item)
    return value if isinstance(value, list) else [value]

def get_options_from_call(call):
    source = DEFAULT_SOURCE
    no_basemap = False
    for flag, val in call.get("named", []):
        if not isinstance(flag, dict):
            continue
        if flag.get("item") == "source" and "String" in val:
            source = val["String"]["val"]
        elif flag.get("item") == "no-basemap" and "Bool" in val:
            no_basemap = val["Bool"]["val"]
    return source, no_basemap

def make_pipeline_data_string(svg, span):
    return {"PipelineData": {"Value": [{"String": {"val": svg, "span": span}}, None]}}

def make_error_response(call_id, msg, span=None):
    if span:
        err = {"Error": {"msg": msg, "labels": [{"text": msg, "span": span}]}}
    else:
        err = {"Error": {"msg": msg, "help": msg}}
    return {"CallResponse": [call_id, err]}

def process_run(call_id, run, pending, write):
    name = run.get("name")
    if name in ("plot lines", "lines"):
        command = "lines"
    elif name in ("plot dots", "dots"):
        command = "dots"
    else:
        write({"CallResponse": [call_id, {"Error": {"msg": "unknown command"}}]})
        return
    call = run.get("call", {})
    source, no_basemap = get_options_from_call(call)
    input_header = run.get("input", {})
    span = call.get("head", {"start": 0, "end": 0})

    if "Value" in input_header:
        value_obj, _ = input_header["Value"]
        try:
            value = extract_value(value_obj)
            if command == "lines":
                svg = render_lines_svg(lines_from_value(value))
            else:
                if not isinstance(value, list):
                    raise ValueError("expected list")
                svg = render_svg(extract_points_from_records(value), source, no_basemap)
            write({"CallResponse": [call_id, make_pipeline_data_string(svg, span)]})
        except Exception as e:  # noqa: BLE001
            write(make_error_response(call_id, str(e), span))
        return

    if "ListStream" in input_header:
        stream_id = input_header["ListStream"]["id"]
        pending[stream_id] = {
            "call_id": call_id,
            "command": command,
            "source": source,
            "no_basemap": no_basemap,
            "items": [],
            "span": span,
        }
        return

    write(make_error_response(call_id, "unsupported input", span))

def plugin_loop(input_iter, write):
    pending = {}
    for raw in input_iter:
        if not raw.strip():
            continue
        msg = json.loads(raw)
        if "Hello" in msg:
            continue
        if "Goodbye" in msg:
            break
        if "Call" in msg:
            call_id, call = msg["Call"]
            if isinstance(call, str):
                call = {call: None}
            if isinstance(call, dict):
                if "Signature" in call:
                    write({"CallResponse": [call_id, signatures()]})
                elif "Metadata" in call:
                    write({"CallResponse": [call_id, {"Metadata": {"version": PLUGIN_VERSION}}]})
                elif "Run" in call:
                    process_run(call_id, call["Run"], pending, write)
                else:
                    write({"CallResponse": [call_id, {"Error": {"msg": "unknown call"}}]})
            else:
                write({"CallResponse": [call_id, {"Error": {"msg": "unknown call"}}]})
            continue
        if "Data" in msg:
            stream_id, data = msg["Data"]
            if stream_id in pending:
                pending[stream_id]["items"].append(data)
            # Acknowledge consumption so the engine's flow-controlled writer (which pauses
            # after 100 un-acknowledged messages) can keep sending the rest of the stream.
            write({"Ack": stream_id})
            continue
        if "End" in msg:
            stream_id = msg["End"]
            if stream_id in pending:
                info = pending.pop(stream_id)
                call_id = info["call_id"]
                span = info["span"]
                try:
                    rows = [row for item in info["items"] for row in extract_rows(item)]
                    if info["command"] == "lines":
                        svg = render_lines_svg(lines_from_value(rows))
                    else:
                        svg = render_svg(
                            extract_points_from_records(rows), info["source"], info["no_basemap"]
                        )
                    write({"CallResponse": [call_id, make_pipeline_data_string(svg, span)]})
                except Exception as e:  # noqa: BLE001
                    write(make_error_response(call_id, str(e), span))
            continue

def main():
    sys.stdout.buffer.write(b"\x04json")
    sys.stdout.flush()
    hello = {"Hello": {"protocol": "nu-plugin", "version": NUSHELL_VERSION, "features": []}}
    sys.stdout.write(json.dumps(hello) + "\n")
    sys.stdout.flush()

    def write(obj):
        sys.stdout.write(json.dumps(obj) + "\n")
        sys.stdout.flush()

    def line_iter():
        for line in sys.stdin:
            line = line.strip()
            if line:
                yield line

    plugin_loop(line_iter(), write)

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--stdio":
        main()
    else:
        print("Run me from inside nushell!")
