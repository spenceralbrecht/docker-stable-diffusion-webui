ARG BASEIMAGE
ARG BASETAG

# STAGE FOR CACHING APT PACKAGE LIST
FROM ${BASEIMAGE}:${BASETAG} as stage_apt

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN \
    rm -rf /etc/apt/apt.conf.d/docker-clean \
	&& echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
	&& apt-get update

# STAGE FOR INSTALLING APT DEPENDENCIES
FROM ${BASEIMAGE}:${BASETAG} as stage_deps

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

COPY deps/aptDeps.txt /tmp/aptDeps.txt

# INSTALL APT DEPENDENCIES USING CACHE OF stage_apt
RUN \
    --mount=type=cache,target=/var/cache/apt,from=stage_apt,source=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt,from=stage_apt,source=/var/lib/apt \
    --mount=type=cache,target=/etc/apt/sources.list.d,from=stage_apt,source=/etc/apt/sources.list.d \
	apt-get install --no-install-recommends -y $(cat /tmp/aptDeps.txt) \
    && rm -rf /tmp/*

# ADD NON-ROOT USER user FOR RUNNING THE WEBUI
RUN \
    groupadd user \
    && useradd -ms /bin/bash user -g user \
    && echo "user ALL=NOPASSWD: ALL" >> /etc/sudoers


# STAGE FOR BUILDING APPLICATION CONTAINER
FROM stage_deps as stage_app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    DEBIAN_FRONTEND=noninteractive \
    FORCE_CUDA=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LD_LIBRARY_PATH=/usr/local/cuda-11.7/lib64:$LD_LIBRARY_PATH \
    NVCC_FLAGS="--use_fast_math -DXFORMERS_MEM_EFF_ATTENTION_DISABLE_BACKWARD"\
    PATH=/usr/local/cuda-11.7/bin:$PATH \
    TORCH_CUDA_ARCH_LIST="6.0;6.1;6.2;7.0;7.2;7.5;8.0;8.6" \
    XFORMERS_DISABLE_FLASH_ATTN=1

# SWITCH TO THE GENERATED USER
WORKDIR /home/user
USER user

# CLONE AND PREPARE FOR THE SETUP OF SD-WEBUI
RUN \ 
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git \
    # CHECKOUT TO COMMIT a9eab236d7e8afa4d6205127904a385b2c43bb24
    # && git -C /home/user/stable-diffusion-webui reset --hard 7f4d774eb650c8a3324f28945e5e743c905caa50 \
    && sed -i \
        "s/#export COMMANDLINE_ARGS=\"\"/export COMMANDLINE_ARGS=\"\
            --listen \
            --xformers \
            --skip-torch-cuda-test \
            --styles-file styles\/styles.csv \
            --no-download-sd-model \
            --enable-insecure-extension-access\"/g" \
        /home/user/stable-diffusion-webui/webui-user.sh \
    && chmod +x /home/user/stable-diffusion-webui/webui-user.sh \
    && mkdir /home/user/stable-diffusion-webui/styles \
    && mkdir -p /home/user/stable-diffusion-webui/outputs/txt2img-images \
    && chmod -R 777 /home/user/stable-diffusion-webui/outputs/

# SETUP STABLE-DIFFUSION-WEBUI WITH THE SCRIPT PROVIDED
COPY --chmod=777 --chown=user:user \
    scripts/setup.sh /tmp/setup.sh

RUN \
    wget -O \
        /home/user/stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned-emaonly.safetensors \
        https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors \
    && COMMANDLINE_ARGS="--skip-torch-cuda-test --no-download-sd-model" \
        /home/user/stable-diffusion-webui/webui.sh \
    & /tmp/setup.sh \
    && rm -rf /tmp/* \
    && COMMANDLINE_ARGS="--skip-torch-cuda-test --no-download-sd-model" \
    && /tmp/setup.sh \
    && rm -rf /tmp/*

# INSTALL PYTHON DEPENDENCIES THAT ARE NOT INSTALLED BY THE SCRIPT
COPY --chown=user:user \
    deps/pyDeps.txt /tmp/pyDeps.txt

RUN \
    python3 -m venv /home/user/stable-diffusion-webui/venv \
    && source /home/user/stable-diffusion-webui/venv/bin/activate \
    && python3 -m pip install $(cat /tmp/pyDeps.txt) \
    && rm -rf /tmp/*

# INCLUDE AUTO COMPLETION JAVASCRIPT
RUN \
    curl -o /home/user/stable-diffusion-webui/javascript/auto_completion.js \
        https://greasyfork.org/scripts/452929-webui-%ED%83%9C%EA%B7%B8-%EC%9E%90%EB%8F%99%EC%99%84%EC%84%B1/code/WebUI%20%ED%83%9C%EA%B7%B8%20%EC%9E%90%EB%8F%99%EC%99%84%EC%84%B1.user.js

# COPY entrypoint.sh
COPY --chmod=775 scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /home/user/stable-diffusion-webui

# PORT AND ENTRYPOINT, USER SETTINGS
EXPOSE 7860
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# DOCKER IAMGE LABELING
LABEL title="Stable-Diffusion-Webui-Docker"
LABEL version="1.2.0"

# ---------- BUILD COMMAND ----------
# DOCKER_BUILDKIT=1 docker build --no-cache \
# --build-arg BASEIMAGE=nvidia/cuda \
# --build-arg BASETAG=11.7.1-cudnn8-devel-ubuntu22.04 \
# -t kestr3l/stable-diffusion-webui:1.2.0 \
# -f Dockerfile .
