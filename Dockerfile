FROM registry.runpod.net/runpod-workers-worker-a1111-main-dockerfile:022c30933

ADD --chmod=644 https://civitai.com/api/download/models/2741698?type=Model&format=SafeTensor&size=pruned&fp=fp16 /model.safetensors
