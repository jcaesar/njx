#!/usr/bin/env python3
"""Nushell plugin: dots
Input a list of lon/lat records, output SVG map with contextily basemap.
"""
import io
import json
import sys

PLUGIN_VERSION = "0.1.0"
NUSHELL_VERSION = "0.115.0"
DEFAULT_SOURCE = "Esri.WorldGrayCanvas"

def signatures():
    return {
        "Signature": [
            {
                "sig": {
                    "name": "dots",
                    "description": "Plot lon/lat points on a map and output SVG",
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
            }
        ]
    }

def extract_points_from_records(vals):
    points = []
    for v in vals:
        if "Record" not in v:
            raise ValueError("expected Record")
        rec = v["Record"]["val"]
        if "lon" not in rec or "lat" not in rec:
            raise ValueError("missing lon/lat")
        lon_node = rec["lon"]
        lat_node = rec["lat"]
        if "Float" in lon_node:
            lon = lon_node["Float"]["val"]
        elif "Int" in lon_node:
            lon = float(lon_node["Int"]["val"])
        else:
            raise ValueError("lon not int/float")
        if "Float" in lat_node:
            lat = lat_node["Float"]["val"]
        elif "Int" in lat_node:
            lat = float(lat_node["Int"]["val"])
        else:
            raise ValueError("lat not float/int")
        points.append({"lon": lon, "lat": lat})
    return points

def render_svg(points, source, no_basemap=False):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import geopandas as gpd
    from shapely.geometry import Point

    fig, ax = plt.subplots(figsize=(16,16))

    geometry = [Point(p["lon"], p["lat"]) for p in points]
    crs = 4326
    gpd.GeoDataFrame(geometry=geometry, crs=crs).plot(ax=ax)

    if not no_basemap:
        import contextily as ctx
        ctx.add_basemap(ax, source=source, crs=crs, extent=extent)

    buf = io.BytesIO()
    fig.savefig(buf, format="svg")
    plt.close(fig)
    return buf.getvalue().decode("utf-8")

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
    if name != "dots":
        write({"CallResponse": [call_id, {"Error": {"msg": "unknown command"}}]})
        return
    call = run.get("call", {})
    source, no_basemap = get_options_from_call(call)
    input_header = run.get("input", {})
    span = call.get("head", {"start": 0, "end": 0})

    if "Value" in input_header:
        value_obj, _ = input_header["Value"]
        try:
            if "List" not in value_obj:
                raise ValueError("expected list")
            vals = value_obj["List"]["vals"]
            points = extract_points_from_records(vals)
            svg = render_svg(points, source, no_basemap)
            write({"CallResponse": [call_id, make_pipeline_data_string(svg, span)]})
        except Exception as e:  # noqa: BLE001
            write(make_error_response(call_id, str(e), span))
        return

    if "ListStream" in input_header:
        stream_id = input_header["ListStream"]["id"]
        pending[stream_id] = {"call_id": call_id, "source": source, "no_basemap": no_basemap, "items": [], "span": span}
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
            if stream_id in pending and "List" in data:
                pending[stream_id]["items"].append(data["List"])
            continue
        if "End" in msg:
            stream_id = msg["End"]
            if stream_id in pending:
                info = pending.pop(stream_id)
                call_id = info["call_id"]
                source = info["source"]
                no_basemap = info["no_basemap"]
                span = info["span"]
                items = info["items"]
                try:
                    points = extract_points_from_records(items)
                    svg = render_svg(points, source, no_basemap)
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
