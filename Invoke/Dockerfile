FROM alpine:3.17 as xformers
RUN apk add --no-cache aria2
RUN aria2c -x 5 --dir / --out wheel.whl 'https://github.com/AbdBarho/stable-diffusion-webui-docker/releases/download/6.0.0/xformers-0.0.21.dev544-cp310-cp310-manylinux2014_x86_64-pytorch201.whl'


#FROM python:3.10.9-slim as source
# patch match:
# https://github.com/invoke-ai/InvokeAI/blob/main/docs/installation/INSTALL_PATCHMATCH.md
#RUN apt-get update && apt-get install  git -y
#ENV ROOT=/InvokeAI
#RUN git clone https://github.com/invoke-ai/InvokeAI.git ${ROOT}

# #### Build the Web UI ------------------------------------

#FROM node:18 AS web-builder
#WORKDIR /build
#COPY --from=source /InvokeAI/invokeai/frontend/web/ ./
#RUN --mount=type=cache,target=/usr/lib/node_modules \
#    npm install --include dev
#RUN --mount=type=cache,target=/usr/lib/node_modules \
#    yarn vite build

FROM python:3.10.9-slim
ENV DEBIAN_FRONTEND=noninteractive PIP_EXISTS_ACTION=w PIP_PREFER_BINARY=1
# patch match:
# https://github.com/invoke-ai/InvokeAI/blob/main/docs/installation/INSTALL_PATCHMATCH.md
RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update && \
  apt-get install make g++ git libopencv-dev -y && \
  apt-get clean && \
  cd /usr/lib/x86_64-linux-gnu/pkgconfig/ && ln -sf opencv4.pc opencv.pc
  

ARG TORCH_VERSION=2.0.1
ARG TORCHVISION_VERSION=0.15.2

ENV ROOT=/InvokeAI
RUN git clone https://github.com/invoke-ai/InvokeAI.git ${ROOT}
WORKDIR ${ROOT}

RUN --mount=type=cache,target=/root/.cache/pip \
#  git reset --hard f3b2e02921927d9317255b1c3811f47bd40a2bf9 && \
  pip install \
       --extra-index-url https://download.pytorch.org/whl/cpu \
        torch==$TORCH_VERSION \
        torchvision==$TORCHVISION_VERSION \
  pip install -e .


#ARG BRANCH=main
#ARG SHA=f3b2e02921927d9317255b1c3811f47bd40a2bf9
#RUN --mount=type=cache,target=/root/.cache/pip \
#  git fetch && \
#  git reset --hard && \
#  git checkout ${BRANCH} && \
#  git reset --hard ${SHA} && \
#  pip install -U -e .
# COPY xformers-0.0.21.dev544-cp310-cp310-manylinux2014_x86_64-pytorch201.whl  /whl/xformers-0.0.21-cp310-cp310-linux_x86_64.whl
RUN --mount=type=cache,target=/root/.cache/pip \
 --mount=type=bind,from=xformers,source=/wheel.whl,target=/xformers-0.0.21-cp310-cp310-linux_x86_64.whl \
  pip install -U opencv-python-headless triton /xformers-0.0.21-cp310-cp310-linux_x86_64.whl && \
  python3 -c "from patchmatch import patch_match"

#COPY --from=web-builder /build/dist ${ROOT}/invokeai/frontend/web/dist


#[--host HOST] [--port PORT] [--allow_origins [ALLOW_ORIGINS ...]] [--allow_credentials | --no-allow_credentials] [--allow_methods [ALLOW_METHODS ...]]
#[--allow_headers [ALLOW_HEADERS ...]] [--esrgan | --no-esrgan] [--internet_available | --no-internet_available] [--log_tokenization | --no-log_tokenization]
#[--patchmatch | --no-patchmatch] [--restore | --no-restore]
#[--always_use_cpu | --no-always_use_cpu] [--free_gpu_mem | --no-free_gpu_mem] [--max_loaded_models MAX_LOADED_MODELS] [--max_cache_size MAX_CACHE_SIZE]
#[--max_vram_cache_size MAX_VRAM_CACHE_SIZE] [--gpu_mem_reserved GPU_MEM_RESERVED] [--precision {auto,float16,float32,autocast}]
#[--sequential_guidance | --no-sequential_guidance] [--xformers_enabled | --no-xformers_enabled] [--tiled_decode | --no-tiled_decode] [--root ROOT]
#[--autoimport_dir AUTOIMPORT_DIR] [--lora_dir LORA_DIR] [--embedding_dir EMBEDDING_DIR] [--controlnet_dir CONTROLNET_DIR] [--conf_path CONF_PATH]
#[--models_dir MODELS_DIR] [--legacy_conf_dir LEGACY_CONF_DIR] [--db_dir DB_DIR] [--outdir OUTDIR] [--from_file FROM_FILE]
#[--use_memory_db | --no-use_memory_db] [--model MODEL] [--log_handlers [LOG_HANDLERS ...]] [--log_format {plain,color,syslog,legacy}]
#[--log_level {debug,info,warning,error,critical}] [--version | --no-version]

COPY . /docker/
RUN chmod +x /docker/entrypoint.sh
ENV NVIDIA_VISIBLE_DEVICES=all PRELOAD=true
ENV PYTHONUNBUFFERED=1 PRELOAD=false HF_HOME=/root/.cache/huggingface CONFIG_DIR=/data/config/invoke CLI_ARGS="--always_use_cpu"
EXPOSE 7860
VOLUME ["/data","/output"]
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD invokeai --web --host 0.0.0.0 --port 7860 --root ${ROOT}  --conf_path ${CONFIG_DIR}/models.yaml \
  --outdir /output/invoke --embedding_dir /data/embeddings/ --lora_dir /data/models/Lora \
  --db_dir /data/config/invoke \
  ${CLI_ARGS}
