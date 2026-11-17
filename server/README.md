# FC Digital Twin server (v0.1)
Dash dashboard (8050) -> FastAPI (8000) -> Celery worker (Redis) -> FMU (FMPy) and stage A calibration.
See the deployment steps in the project guide. Quick version, from this folder on the server:
  cp .env.example .env   # edit MODELS and API_KEY
  docker compose build
  docker compose --profile build run --rm fmu-builder   # builds the Linux FMUs into the "fmu" volume
  docker compose up -d
