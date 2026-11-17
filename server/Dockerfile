# One image does everything (builds FMUs, runs API, worker, dashboard), so the FMU
# and the program that runs it share the same Linux libraries.
ARG OM_TAG=v1.25.0-minimal
FROM openmodelica/openmodelica:${OM_TAG}
USER root
ENTRYPOINT []
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-venv python3-pip \
    && rm -rf /var/lib/apt/lists/* && python3 -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH
COPY server/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
COPY modelica /src
COPY server/build_fmu.sh /build_fmu.sh
COPY server/app /app/app
WORKDIR /app
