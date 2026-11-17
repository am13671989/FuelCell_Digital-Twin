import base64, os, requests
import plotly.graph_objects as go
from dash import Dash, Input, Output, State, dcc, html, no_update
from plotly.subplots import make_subplots

API = os.getenv("API_URL", "http://localhost:8000")
H = {"X-API-Key": os.getenv("API_KEY", "")}
app = Dash(__name__)

def layout():
    try:
        opts = requests.get(f"{API}/models", headers=H, timeout=5).json()
    except Exception:
        opts = []
    box = {"width": 110, "marginRight": 8}
    return html.Div(style={"maxWidth": 1000, "margin": "1.5rem auto", "fontFamily": "sans-serif"}, children=[
        html.H2("Fuel Cell Digital Twin"),
        dcc.Dropdown(id="model", options=opts, value=opts[0] if opts else None, placeholder="Select an FMU model"),
        html.P("Current profile: input name, current before step (A), after step (A), step time (s), end time (s)"),
        html.Div([dcc.Input(id=k, value=v, style=box) for k, v in
                  [("iname", "I_load"), ("i1", "100"), ("i2", "350"), ("tstep", "100"), ("tend", "500")]]),
        html.P("Outputs (comma separated names from the FMU)"),
        dcc.Input(id="outs", value="V_stack,T,Tcool,OER,eta_net", style={"width": 420}),
        html.Button("Run simulation", id="run", style={"marginLeft": 12}), html.Span(id="st", style={"marginLeft": 12}),
        dcc.Store(id="job"), dcc.Store(id="cjob"), dcc.Interval(id="tick", interval=1500),
        dcc.Graph(id="fig"), html.Hr(), html.H3("Calibration, stage A (polarization curve)"),
        dcc.Upload(id="up", children=html.Div("Drop a CSV with columns i (A/cm2) and v (V per cell)"),
                   style={"border": "1px dashed #888", "padding": 16}),
        html.Button("Calibrate", id="cal"), html.Pre(id="calout")])

app.layout = layout

@app.callback(Output("job", "data"), Input("run", "n_clicks"), State("model", "value"), State("iname", "value"),
              State("i1", "value"), State("i2", "value"), State("tstep", "value"), State("tend", "value"),
              State("outs", "value"), prevent_initial_call=True)
def run(_, model, iname, i1, i2, ts, te, outs):
    ts, te, i1, i2 = float(ts), float(te), float(i1), float(i2)
    body = {"model": model, "t_end": te, "inputs": {"time": [0, ts, ts, te], iname: [i1, i1, i2, i2]},
            "outputs": [o.strip() for o in outs.split(",") if o.strip()]}
    return requests.post(f"{API}/simulate", json=body, headers=H).json().get("job_id")

@app.callback(Output("st", "children"), Output("fig", "figure"), Input("tick", "n_intervals"), State("job", "data"))
def poll(_, job):
    if not job:
        return "", no_update
    r = requests.get(f"{API}/jobs/{job}", headers=H).json()
    if r["state"] != "SUCCESS":
        return r["state"] if not r["result"] else r["result"], no_update
    d = r["result"]; names = [k for k in d if k != "time"]
    f = make_subplots(rows=len(names), cols=1, shared_xaxes=True, subplot_titles=names)
    for k, n in enumerate(names, 1):
        f.add_trace(go.Scatter(x=d["time"], y=d[n], name=n), row=k, col=1)
    f.update_layout(height=220 * len(names), showlegend=False, xaxis_title="time (s)")
    return "done", f

@app.callback(Output("cjob", "data"), Input("cal", "n_clicks"), State("up", "contents"), prevent_initial_call=True)
def calibrate(_, contents):
    raw = base64.b64decode(contents.split(",")[1])
    return requests.post(f"{API}/calibrate/stage-a", files={"file": ("d.csv", raw)}, headers=H).json().get("job_id")

@app.callback(Output("calout", "children"), Input("tick", "n_intervals"), State("cjob", "data"))
def poll_cal(_, job):
    if not job:
        return ""
    r = requests.get(f"{API}/jobs/{job}", headers=H).json()
    if r["state"] != "SUCCESS":
        return r["state"]
    d = r["result"]
    return "RMSE %.1f mV\n" % (d["rmse_V"] * 1000) + "\n".join(
        "%-9s %9.4g   90%% interval %.3g to %.3g" % (k, v, *d["ci90"][k]) for k, v in d["params"].items())

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8050)
