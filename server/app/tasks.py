import os
import numpy as np
from celery import Celery
from .calib import calibrate

REDIS = os.getenv("REDIS_URL", "redis://localhost:6379/0")
FMU_DIR = os.getenv("FMU_DIR", "/fmu")
DEFAULT_OUTPUTS = ["V_stack", "T", "Tcool", "OER", "eta_net"]
celery = Celery("fcdt", broker=REDIS, backend=REDIS)
celery.conf.result_expires = 86400

@celery.task
def simulate(model, t_end, inputs, params, outputs):
    """Run an FMU. inputs = {"time": [...], "I_load": [...]} (repeat a time stamp for a step)."""
    from fmpy import read_model_description, simulate_fmu
    path = os.path.join(FMU_DIR, os.path.basename(model) + ".fmu")
    names = {v.name for v in read_model_description(path).modelVariables}
    outs = [o for o in (outputs or DEFAULT_OUTPUTS) if o in names]
    if not outs:
        raise ValueError("none of the requested outputs exist in this FMU")
    keys = [k for k in inputs if k != "time" and k in names]
    inp = np.rec.fromarrays([np.array(inputs["time"], float)] + [np.array(inputs[k], float) for k in keys],
                            names=["time"] + keys) if keys else None
    r = simulate_fmu(path, stop_time=t_end, output_interval=t_end / 1000, input=inp,
                     start_values={k: v for k, v in params.items() if k in names},
                     output=outs, fmi_type="CoSimulation")
    return {n: r[n].tolist() for n in ["time"] + outs}

@celery.task
def calibrate_a(i, v, cond):
    return calibrate(i, v, **cond)
