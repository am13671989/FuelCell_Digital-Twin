import io, os
from typing import Dict, List, Optional
import pandas as pd
from celery.result import AsyncResult
from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, UploadFile
from pydantic import BaseModel
from .tasks import FMU_DIR, calibrate_a, celery, simulate

def auth(x_api_key: Optional[str] = Header(None)):
    key = os.getenv("API_KEY")
    if key and x_api_key != key:
        raise HTTPException(401, "bad or missing X-API-Key header")

app = FastAPI(title="FC Digital Twin API", version="0.1.0", dependencies=[Depends(auth)])

class SimRequest(BaseModel):
    model: str
    t_end: float = 300
    inputs: Dict[str, List[float]] = {}
    params: Dict[str, float] = {}
    outputs: List[str] = []

def fmus():
    return sorted(f[:-4] for f in os.listdir(FMU_DIR) if f.endswith(".fmu")) if os.path.isdir(FMU_DIR) else []

@app.get("/health")
def health():
    return {"status": "ok", "models": len(fmus())}

@app.get("/models")
def models():
    return fmus()

@app.post("/simulate")
def start_simulation(r: SimRequest):
    if r.model not in fmus():
        raise HTTPException(404, "unknown model; see GET /models")
    return {"job_id": simulate.delay(r.model, r.t_end, r.inputs, r.params, r.outputs).id}

@app.post("/calibrate/stage-a")
async def start_calibration(file: UploadFile = File(...), T: float = Form(353.15),
                            pH2: float = Form(1.5), pO2: float = Form(0.3)):
    df = pd.read_csv(io.BytesIO(await file.read()))  # columns: i (A/cm2), v (V per cell)
    return {"job_id": calibrate_a.delay(df["i"].tolist(), df["v"].tolist(), {"T": T, "pH2": pH2, "pO2": pO2}).id}

@app.get("/jobs/{job_id}")
def job(job_id: str):
    r = AsyncResult(job_id, app=celery)
    return {"state": r.state, "result": r.result if r.successful() else (str(r.result) if r.failed() else None)}
