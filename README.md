# Stable-Diffusion-Webui-Docker
- Dockerized Stable-Diffusion-Webui based on [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
- Includes [facebookreseasrch/xformers](https://github.com/facebookresearch/xformers)
- Includes [prompt auto-completion javascript](https://greasyfork.org/ko/scripts/452929-webui-%ED%83%9C%EA%B7%B8-%EC%9E%90%EB%8F%99%EC%99%84%EC%84%B1) credited by [shounksu](https://greasyfork.org/ko/users/815641-shounksu)
- Image is based on nvidia/cuda:11.7.1-devel-ubuntu22.04 image
- Prebuilt images are available on Docker Hub:
  - [kestr3l/stable-diffusion-webui](https://hub.docker.com/r/kestr3l/stable-diffusion-webui)

## 0 Prequisites

- Linux environment (WSL2 is fine)
- 'Appropriate' GPU
- [docker-ce](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)
- [docker-compose](https://docs.docker.com/compose/install/)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Basic knowledges of Linux commands

## 1 stable-diffusion-webui

### 1.1 Building `stable-diffusion-webui` Docker Image

You will first need to enable [Docker BuildKit](https://docs.docker.com/build/buildkit/) by setting the following environment variable `DOCKER_BUILDKIT=1` which will allow stages to run concurrently. 
If you have a path `/etc/docker/` in the environment you are running this in then make sure the file `/etc/docker/daemon.json` exists and has the following contents
```
{
  "features": {
    "buildkit" : true
  }
}
```

### Download a model to use 
`wget -O ./models/ https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors`

```shell
DOCKER_BUILDKIT=1 

sudo docker build --no-cache \
--build-arg BASEIMAGE=nvidia/cuda \
--build-arg BASETAG=11.7.1-devel-ubuntu20.04 \
-t spencer/stable-diffusion-webui:1.0.0 \
-f Dockerfile .
```

> Build may fail on WSL2. If so, try to build it on native linux environment.

### 1.2 Running `docker-stable-diffusion-webui` Container

> I stronly recommend to run this container by `docker-compose` due to complexity of settings. Also, suggested `docker run` commands are outdated.

- Basic docker CLI command of running a container is suggested as below
- You need to prepare a model on your own since I can't provide it
- Based on your need, set your own port to connect
  - Instead of setting a port, you can use `--net host` which makes container to use host network adapter
- Mount any settings file or volume based on your need
  - Example command below contains all common possible options

## V4
```shell
sudo docker run --gpus all -it --rm --name stable-diffusion-webui \
  --privileged \
  -e NVIDIA_DISABLE_REQUIRE=1 \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e UID=$(id -u) \
  -e GID=$(id -g) \
  -e DIR_GRADIO_AUTH=/run/secrets/gradio_auth \
  -v /outputs:/home/user/stable-diffusion-webui/outputs \
  -v /styles:/home/user/stable-diffusion-webui/styles \
  -v /extensions:/home/user/stable-diffusion-webui/models/extensions \
  -v /VAE:/home/user/stable-diffusion-webui/models/VAE \
  -v $(pwd)/config.json:/home/user/stable-diffusion-webui/config.json \
  -v $(pwd)/webui-user.sh:/home/user/stable-diffusion-webui/webui-user.sh \
  -v /path/to/your/secrets/gradio_auth.txt:/run/secrets/gradio_auth \
  -p 80:7860 \
  kestr3l/stable-diffusion-webui:1.2.2
```

## V3
```shell
sudo docker run --gpus all -it --rm --name stable-diffusion-webui \
  --privileged \
  -e NVIDIA_DISABLE_REQUIRE=1 \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e UID=$(id -u) \
  -e GID=$(id -g) \
  -e DIR_GRADIO_AUTH=/run/secrets/gradio_auth \
  -v /outputs:/home/user/stable-diffusion-webui/outputs \
  -v /styles:/home/user/stable-diffusion-webui/styles \
  -v /models:/home/user/stable-diffusion-webui/models \
  -v /extensions:/home/user/stable-diffusion-webui/models/extensions \
  -v /VAE:/home/user/stable-diffusion-webui/models/VAE \
  -v $(pwd)/config.json:/home/user/stable-diffusion-webui/config.json \
  -v /path/to/your/secrets/gradio_auth.txt:/run/secrets/gradio_auth \
  -p 80:7860 \
  spencer/stable-diffusion-webui:1.0.0
```
## V2
```shell
sudo docker run -it --rm --name stable-diffusion-webui \
  --privileged \
  -e NVIDIA_DISABLE_REQUIRE=1 \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -e UID=$(id -u) \
  -e GID=$(id -g) \
  -e DIR_GRADIO_AUTH=/run/secrets/gradio_auth \
  -v /models:/home/user/stable-diffusion-webui/models/Stable-diffusion \
  -v /outputs:/home/user/stable-diffusion-webui/outputs \
  -v /styles:/home/user/stable-diffusion-webui/styles \
  -v /extensions:/home/user/stable-diffusion-webui/models/extensions \
  -v /VAE:/home/user/stable-diffusion-webui/models/VAE \
  -v config.json:/home/user/stable-diffusion-webui/config.json \
  -v webui-user.sh:/home/user/stable-diffusion-webui/webui-user.sh \
  -v /path/to/your/secrets/gradio_auth.txt:/run/secrets/gradio_auth \
  -p 80:7860 \
  kestr3l/stable-diffusion-webui:1.2.0
```
## V1
```shell
docker run -it --rm \
    --name stable-diffusion-webui \
    -e NVIDIA_DISABLE_REQUIRE=1 \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e UID=$(id -u) \
    -e GID=$(id -g) \
    -v <YOUR_DIRECTORY_TO_MODELS>:/home/user/stable-diffusion-webui/models/Stable-diffusion
    -v <YOUR_DIRECTORY_TO_OUTPUT>:/home/user/stable-diffusion-webui/outputs
    -v <YOUR_DIRECTORY_TO_STYLES>:/home/user/stable-diffusion-webui/styles
    -v <YOUR_DIRECTORY_TO_EXTENSIONS>:/home/user/stable-diffusion-webui/models/extensions
    -v <YOUR_DIRECTORY_TO_VAE>:/home/user/stable-diffusion-webui/models/VAE
    -v <YOUR_DIRECTORY_TO_config.json>:/home/user/stable-diffusion-webui/config.json
    -v <YOUR_DIRECTORY_TO_ui-config.json>:/home/user/ui-config.json.bak
    -v <YOUR_DIRECTORY_TO_webui-user.sh>:/home/user/stable-diffusion-webui/webui-user.sh
    -p <YOUR_PREFFERED_PORT>:7860 \
    --gpus all \
    --privileged \
    kestr3l/stable-diffusion-webui:1.1.0
```

> Use `-itd` instead of `-d` for background execution

- If you prefer `docker-compose`, simply run following command after modifying given `docker-compose.yml`

```shell
docker-compose up
```

> To run it on background, add `-d`

- Then connect to `http://localhost:<YOUR_PREFFERED_PORT>` or `http://<private_ip>:<YOUR_PREFFERED_PORT>`

### 1.3 Mapping Directories and Files to the Host

- Map directories as below to add new models, styles or VAEs in easy way:
  - If you want to add a new elements, simple copy a file into mapped directory
  - For example, simpley copy `.safetensor` file into mapped model directory for tyring a new model

```shell
-v <YOUR_DIRECTORY_TO_MODELS>:/home/user/stable-diffusion-webui/models/Stable-diffusion
-v <YOUR_DIRECTORY_TO_STYLES>:/home/user/stable-diffusion-webui/styles
-v <YOUR_DIRECTORY_TO_VAE>:/home/user/stable-diffusion-webui/models/VAE
-v <YOUR_DIRECTORY_TO_EXTENSIONS>:/home/user/stable-diffusion-webui/models/extensions
```

> Mapping some directories will require corresponding commandline prompt.
> - Mapping `styles` directory always require `--styles-file styles/styles.csv
> - Mapping extensions directory with `--listen` always require `--enable-insecure-extension-access`

- Map `output` directory as below to retrieve output imaged through host directory:

```shell
-v <YOUR_DIRECTORY_TO_OUTPUT>:/home/user/stable-diffusion-webui/outputs
```

- Map following files to keep settings of the webui
  - `webui-user.sh` sets commandline prompts for running the WebUI
  - **Commandline prompt MUST INCLUDE** these: `--xformers --skip-torch-cuda-test --styles-file styles/styles.csv`
  - Recommended prompt is: `--listen --enable-insecure-extension-access --xformers --skip-torch-cuda-test --gradio-auth <USERNAME>:<PASSWORD> --styles-file styles/styles.csv`

```shell
    -v <YOUR_DIRECTORY_TO_config.json>:/home/user/stable-diffusion-webui/config.json
    -v <YOUR_DIRECTORY_TO_ui-config.json>:/home/user/ui-config.json.bak
    -v <YOUR_DIRECTORY_TO_webui-user.sh>:/home/user/stable-diffusion-webui/webui-user.sh
```

### 1.4 Debugging `stable-diffusion-webui` Docker Image

- Replace `entrypoint.sh to entrypoint-debug.sh`
- This will make container do 'nothing'. So that user can try anything manually
- Mount additional volumes based on your need

```shell
docker run -it --rm \
    --name stable-diffusion-webui-dbg \
    -e NVIDIA_DISABLE_REQUIRE=1 \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e UID=$(id -u) \
    -e GID=$(id -g) \
    ....
    -v <YOUR_DIRECTORY_TO_entrypoint-debug.sh>:/usr/local/bin/entrypoint.sh
    -p <YOUR_PREFFERED_PORT>:7860 \
    --gpus all \
    --privileged \
    kestr3l/stable-diffusion-webui:1.1.0
```

- Then enter the container by `docker exec -it stable-diffusion-webui-dbg bash'
- If you need to act as `user` instead of `root`, type `su user`

## 2 References

1. [AUTOMATIC1111/stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
2. [facebookreseasrch/xformers](https://github.com/facebookresearch/xformers)
3. [WebUI 태그 자동완성](https://greasyfork.org/ko/scripts/452929-webui-%ED%83%9C%EA%B7%B8-%EC%9E%90%EB%8F%99%EC%99%84%EC%84%B1)
4. [리눅스 xformers 빌드 방법 (GPU 불필요) (작성 중)](https://arca.live/b/aiart/60664075) 
5. [Is it possible to map a user inside the docker container to an outside user?](https://stackoverflow.com/questions/57776452/is-it-possible-to-map-a-user-inside-the-docker-container-to-an-outside-user)
