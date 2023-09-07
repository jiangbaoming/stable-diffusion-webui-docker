#!/bin/bash

set -Eeuo pipefail

declare -A MOUNTS

# mkdir -p ${CONFIG_DIR} ${ROOT}/configs/stable-diffusion/

# cache
MOUNTS["/root/.cache"]=/data/.cache/

# this is really just a hack to avoid migrations
rm -rf ${HF_HOME}/diffusers

# ui specific
MOUNTS["${INVOKEAI_ROOT}/models/codeformer"]=/data/models/Codeformer/
MOUNTS["${INVOKEAI_ROOT}/models/gfpgan/GFPGANv1.4.pth"]=/data/models/GFPGAN/GFPGANv1.4.pth
MOUNTS["${INVOKEAI_ROOT}/models/gfpgan/weights"]=/data/models/GFPGAN/
MOUNTS["${INVOKEAI_ROOT}/models/realesrgan"]=/data/models/RealESRGAN/


MOUNTS["${INVOKEAI_ROOT}/autoimport/controlnet"]=/data/controlnet/
MOUNTS["${INVOKEAI_ROOT}/autoimport/embedding"]=/data/embeddings/
MOUNTS["${INVOKEAI_ROOT}/autoimport/lora"]=/data/models/Lora/
MOUNTS["${INVOKEAI_ROOT}/autoimport/main"]=/data/models/Stable-diffusion/
MOUNTS["${INVOKEAI_ROOT}/autoimport/onnx"]=/data/models/Onnx/
MOUNTS["${INVOKEAI_ROOT}/autoimport/vae"]=/data/models/VAE/

MOUNTS["${INVOKEAI_ROOT}/configs"]=/data/config/invoke/configs/
MOUNTS["${INVOKEAI_ROOT}/databases"]=/data/config/invoke/databases/
MOUNTS["${INVOKEAI_ROOT}/invokeai.yaml"]=/data/config/invoke/invokeai.yaml


MOUNTS["${INVOKEAI_ROOT}/models/ldm"]=/data/.cache/invoke/ldm/

# hacks

for to_path in "${!MOUNTS[@]}"; do
  set -Eeuo pipefail
  from_path="${MOUNTS[${to_path}]}"
  rm -rf "${to_path}"
  mkdir -p "$(dirname "${to_path}")"
  # ends with slash, make it!
  if [[ "$from_path" == */ ]]; then
    mkdir -vp "$from_path"
  fi

  ln -sT "${from_path}" "${to_path}"
  echo Mounted $(basename "${from_path}")
done

# USER_ID=${CONTAINER_UID:-1000}
# USER=invoke
# usermod -u ${USER_ID} ${USER} 1>/dev/null

configure() {
    # Configure the runtime directory
    if [[ -f ${INVOKEAI_ROOT}/invokeai.yaml ]]; then
        echo "${INVOKEAI_ROOT}/invokeai.yaml exists. InvokeAI is already configured."
        echo "To reconfigure InvokeAI, delete the above file."
        echo "======================================================================"
    else
        mkdir -p "${INVOKEAI_ROOT}"
        # chown --recursive ${USER} "${INVOKEAI_ROOT}"
        invokeai-configure --yes --default_only
    fi
}

## Skip attempting to configure.
## Must be passed first, before any other args.
# if [[ $1 != "--no-configure" ]]; then
#     configure
# else
#     shift
# fi


if "${PRELOAD}" == "true"; then
  configure
fi

### Set the $PUBLIC_KEY env var to enable SSH access.
# We do not install openssh-server in the image by default to avoid bloat.
# but it is useful to have the full SSH server e.g. on Runpod.
# (use SCP to copy files to/from the image, etc)
if [[ -v "PUBLIC_KEY" ]] && [[ ! -d "${HOME}/.ssh" ]]; then
    apt-get update
    apt-get install -y openssh-server
    pushd "$HOME"
    mkdir -p .ssh
    echo "${PUBLIC_KEY}" > .ssh/authorized_keys
    chmod -R 700 .ssh
    popd
    service ssh start
fi


cd "${INVOKEAI_ROOT}"


exec "$@"