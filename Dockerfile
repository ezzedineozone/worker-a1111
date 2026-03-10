# ---------------------------------------------------------------------------- #
#                         Stage 1: Download the models                         #
# ---------------------------------------------------------------------------- #
FROM alpine/git:2.43.0 as download

RUN apk add --no-cache wget && \
   wget -q -O /model.safetensors "https://civitai.com/api/download/models/2741698?type=Model&format=SafeTensor&size=pruned&fp=fp16&token=84d6ed18be269a63cec342721f635e4d"

# ---------------------------------------------------------------------------- #
#                        Stage 2: Build the final image                        #
# ---------------------------------------------------------------------------- #
FROM python:3.10.14-slim as build_final_image

ARG A1111_RELEASE=v1.9.3

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    ROOT=/stable-diffusion-webui \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt install -y \
    fonts-dejavu-core rsync git jq moreutils aria2 wget libgoogle-perftools-dev libtcmalloc-minimal4 procps libgl1 libglib2.0-0 && \
    apt-get autoremove -y && rm -rf /var/lib/apt/lists/* && apt-get clean -y

RUN --mount=type=cache,target=/root/.cache/pip \
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd stable-diffusion-webui && \
    git reset --hard ${A1111_RELEASE} && \
    sed -i 's|https://github.com/Stability-AI/stablediffusion.git|https://github.com/CompVis/stable-diffusion.git|g' modules/launch_utils.py && \
    sed -i 's|cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf|69ae4b35e0a0f6ee1af8bb9a5d0016ccb27e36dc|g' modules/launch_utils.py && \
    pip install xformers && \
    pip install -r requirements_versions.txt && \
    python -c "from launch import prepare_environment; prepare_environment()" --skip-torch-cuda-test

COPY --from=download /model.safetensors /model.safetensors

COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

COPY test_input.json .

ADD src .

RUN sed -i 's/\r$//' /start.sh && sed -i 's/\r$//' /handler.py && chmod +x /start.sh

CMD /start.sh
